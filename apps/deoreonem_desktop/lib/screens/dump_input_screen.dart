import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';

class DumpInputScreen extends ConsumerStatefulWidget {
  const DumpInputScreen({super.key});

  @override
  ConsumerState<DumpInputScreen> createState() => _DumpInputScreenState();
}

class _DumpInputScreenState extends ConsumerState<DumpInputScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isAdding = false;
  final List<String> _draftItems = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  /// Add text to local draft list (no API call)
  Future<void> _addDraft() async {
    if (_isAdding) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _draftItems.add(text);
      _controller.clear();
    });
    _scheduleFocusRestore();
  }

  /// Save pending input and navigate to classify — batch-saves all drafts to API
  Future<void> _navigateToClassify() async {
    // Check if IME is composing — if so, cannot save yet
    final composing = _controller.value.composing;
    if (composing.isValid && !composing.isCollapsed) return;

    // Add any remaining typed text to drafts
    final pending = _controller.text.trim();
    if (pending.isNotEmpty) {
      _draftItems.add(pending);
      _controller.clear();
    }

    final items = ref.read(itemsProvider).valueOrNull ?? [];
    if (_draftItems.isEmpty && items.isEmpty) return;

    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    // Batch-save all draft items to API
    setState(() => _isAdding = true);
    try {
      for (final text in _draftItems) {
        await ref.read(itemsProvider.notifier).addItem(session.sessionId, text);
      }
      if (mounted) {
        _draftItems.clear();
        setState(() => _isAdding = false);
        context.go('/classify');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isAdding = false);
        // Stay on screen — error shown
      }
    }
  }

  void _scheduleFocusRestore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 30), () {
          if (mounted && !_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsProvider);
    final savedItems = itemsState.valueOrNull ?? [];
    final hasError = itemsState.hasError;

    // Combined list: saved items + draft items
    final allItems = [
      ...savedItems.map((i) => i.content),
      ..._draftItems,
    ];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오늘 남은 것들',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: const InputDecoration(
                      hintText: '생각, 걱정, 할 일... 하나씩 적어보세요',
                    ),
                    onSubmitted: (_) => _addDraft(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                _isAdding
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _addDraft,
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: '추가',
                      ),
              ],
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              Text(
                '항목 추가에 실패했어요. 다시 시도해 주세요.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: allItems.length,
                itemBuilder: (context, index) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(allItems[index]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  allItems.isNotEmpty && !_isAdding ? _navigateToClassify : null,
              child: const Text('분류하기'),
            ),
          ],
        ),
      ),
    );
  }
}
