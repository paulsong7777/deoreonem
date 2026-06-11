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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    // Request focus on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  Future<void> _addItem() async {
    if (_isAdding) return;

    // Guard against Korean IME composing state
    final composing = _controller.value.composing;
    if (composing.isValid && !composing.isCollapsed) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _isAdding = true);

    try {
      await ref.read(itemsProvider.notifier).addItem(session.sessionId, text);
      if (mounted) {
        // Clear only after success
        _controller.clear();
        setState(() => _isAdding = false);
        _restoreFocus();
      }
    } catch (_) {
      // Keep text on failure — do not clear
      if (mounted) {
        setState(() => _isAdding = false);
        _restoreFocus();
      }
    }
  }

  void _restoreFocus() {
    // Use post-frame callback + short delay to ensure focus survives widget rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && !_focusNode.hasFocus) {
          FocusScope.of(context).requestFocus(_focusNode);
        }
      });
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
    final items = itemsState.valueOrNull ?? [];
    final hasError = itemsState.hasError;

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
                    onSubmitted: (_) => _addItem(),
                    // Never disable — keeps widget tree stable for IME
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
                        onPressed: _addItem,
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
                itemCount: items.length,
                itemBuilder: (context, index) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(items[index].content),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: items.isNotEmpty && !_isAdding
                  ? () => context.go('/classify')
                  : null,
              child: const Text('분류하기'),
            ),
          ],
        ),
      ),
    );
  }
}
