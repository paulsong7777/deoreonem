import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';
import '../theme.dart';

/// DumpInputScreen — single-line thought capture.
/// Uses single-line TextField to avoid Windows Korean IME multiline instability.
/// User enters one thought at a time, adds it to a local pending list,
/// then submits all to the API via "분류하기".
class DumpInputScreen extends ConsumerStatefulWidget {
  const DumpInputScreen({super.key});

  @override
  ConsumerState<DumpInputScreen> createState() => _DumpInputScreenState();
}

class _DumpInputScreenState extends ConsumerState<DumpInputScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final List<String> _pendingThoughts = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    // Request focus after frame to avoid IME init race
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
    setState(() {
      _pendingThoughts.add(text);
    });
    _controller.clear();
    // Keep focus on input for next thought
    _focusNode.requestFocus();
  }

  void _removeThought(int index) {
    setState(() {
      _pendingThoughts.removeAt(index);
    });
  }

  void _onFieldSubmitted(String value) {
    // Enter pressed — add the thought if composition is committed
    _addThought();
  }

  Future<void> _navigateToClassify() async {
    if (_isSaving) return;

    // If there's text in the field but not yet added, add it first
    final currentText = _controller.text.trim();
    if (currentText.isNotEmpty) {
      _pendingThoughts.add(currentText);
      _controller.clear();
    }

    final savedItems = ref.read(itemsProvider).valueOrNull ?? [];
    if (_pendingThoughts.isEmpty && savedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('적어놓은 내용이 없어요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('세션이 없어요. 처음부터 다시 시도해 주세요.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_pendingThoughts.isEmpty) {
      context.go('/classify');
      return;
    }

    setState(() => _isSaving = true);
    try {
      for (final text in _pendingThoughts) {
        await ref.read(itemsProvider.notifier).addItem(session.sessionId, text);
      }
      if (mounted) {
        _pendingThoughts.clear();
        setState(() => _isSaving = false);
        context.go('/classify');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장에 실패했어요: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back navigation
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
            // Title
            Text('마음에 남은 것을 하나씩 덜어내세요.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              '완벽히 정리하지 않아도 괜찮습니다. 떠오른 생각을 하나씩 적어두면 됩니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: AppTheme.secondaryText,
                  ),
            ),
            const SizedBox(height: 24),
            // Single-line input row — FIXED position, never moves
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    // SINGLE LINE — stable with Korean IME on Windows
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _onFieldSubmitted,
                    enableIMEPersonalizedLearning: false,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: '떠오른 생각을 하나씩 적어주세요.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _addThought,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(64, 48), // Override theme's infinite width
                    ),
                    child: const Text('추가'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Pending thoughts list — renders BELOW the input (never shifts it)
            if (_pendingThoughts.isNotEmpty) ...[
              Text('방금 덜어낸 생각',
                  style: TextStyle(fontSize: 12, color: AppTheme.secondaryText, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: _pendingThoughts.isEmpty
                  ? Center(
                      child: Text(
                        '아직 적어둔 생각이 없습니다.',
                        style: TextStyle(fontSize: 13, color: AppTheme.secondaryText.withOpacity(0.6)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _pendingThoughts.length,
                      itemBuilder: (context, index) {
                        return Padding(
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
                                Expanded(
                                  child: Text(_pendingThoughts[index],
                                      style: const TextStyle(fontSize: 14)),
                                ),
                                GestureDetector(
                                  onTap: () => _removeThought(index),
                                  child: Icon(Icons.close, size: 16,
                                      color: AppTheme.secondaryText.withOpacity(0.5)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _navigateToClassify,
                child: _isSaving
                    ? const SizedBox(
                        width: 20, height: 20,
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
