import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';
import '../providers/pending_thoughts_provider.dart';
import '../theme.dart';

class DumpInputScreen extends ConsumerStatefulWidget {
  const DumpInputScreen({super.key});

  @override
  ConsumerState<DumpInputScreen> createState() => _DumpInputScreenState();
}

class _DumpInputScreenState extends ConsumerState<DumpInputScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addThought() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(pendingThoughtsProvider.notifier).add(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _removeThought(int index) {
    ref.read(pendingThoughtsProvider.notifier).removeAt(index);
  }

  void _onFieldSubmitted(String value) {
    _addThought();
  }

  Future<void> _navigateToClassify() async {
    if (_isSaving) return;

    // If text in field, add it first
    final currentText = _controller.text.trim();
    if (currentText.isNotEmpty) {
      ref.read(pendingThoughtsProvider.notifier).add(currentText);
      _controller.clear();
    }

    final pending = ref.read(pendingThoughtsProvider);
    final savedItems = ref.read(itemsProvider).valueOrNull ?? [];
    if (pending.isEmpty && savedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('적어놓은 내용이 없어요.'), duration: Duration(seconds: 2)),
      );
      return;
    }

    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('세션이 없어요. 처음부터 다시 시도해 주세요.'), duration: Duration(seconds: 3)),
      );
      return;
    }

    if (pending.isEmpty) {
      context.go('/classify');
      return;
    }

    setState(() => _isSaving = true);
    try {
      for (final text in pending) {
        await ref.read(itemsProvider.notifier).addItem(session.sessionId, text);
      }
      if (mounted) {
        ref.read(pendingThoughtsProvider.notifier).clear();
        setState(() => _isSaving = false);
        context.go('/classify');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장에 실패했어요: $e'), duration: const Duration(seconds: 4)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingThoughtsProvider);
    final submittedItems = ref.watch(itemsProvider).valueOrNull ?? [];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.go('/'),
              child: Row(
                children: [
                  Icon(Icons.home_outlined, size: 16, color: AppTheme.secondaryText),
                  const SizedBox(width: 4),
                  Text('처음으로', style: TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('마음에 남은 것을 하나씩 덜어내세요.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text('완벽히 정리하지 않아도 괜찮습니다. 떠오른 생각을 하나씩 적어두면 됩니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, color: AppTheme.secondaryText)),
            const SizedBox(height: 24),
            // Input row — single line, fixed position
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _onFieldSubmitted,
                    enableIMEPersonalizedLearning: false,
                    enableSuggestions: false,
                    autocorrect: false,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF2C2C2C)),
                    decoration: InputDecoration(
                      hintText: '떠오른 생각을 하나씩 적어주세요.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addThought,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(64, 48)),
                    child: const Text('추가'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (pending.isNotEmpty)
              Text('방금 덜어낸 생각 (${pending.length}개)',
                  style: TextStyle(fontSize: 12, color: AppTheme.secondaryText, fontWeight: FontWeight.w500)),
            if (pending.isNotEmpty) const SizedBox(height: 8),
            Expanded(
              child: pending.isEmpty
                  ? (submittedItems.isNotEmpty
                      ? ListView(
                          children: [
                            Text('저장 완료 (${submittedItems.length}개)',
                                style: TextStyle(fontSize: 12, color: AppTheme.secondaryText, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            ...submittedItems.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(children: [
                                Icon(Icons.check_circle_outline, size: 14, color: AppTheme.accent),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item.content, style: TextStyle(fontSize: 13, color: AppTheme.secondaryText))),
                              ]),
                            )),
                          ],
                        )
                      : Center(child: Text('아직 적어둔 생각이 없습니다.',
                          style: TextStyle(fontSize: 13, color: AppTheme.secondaryText.withOpacity(0.6)))))
                  : ListView.builder(
                      itemCount: pending.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text(pending[index], style: const TextStyle(fontSize: 14))),
                              GestureDetector(
                                onTap: () => _removeThought(index),
                                child: Icon(Icons.close, size: 16, color: AppTheme.secondaryText.withOpacity(0.5)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: (_isSaving || (pending.isEmpty && submittedItems.isEmpty)) ? null : _navigateToClassify,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('분류하기', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
