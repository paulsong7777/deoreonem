import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';
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
  }

  /// Parse multiline text into non-empty trimmed lines
  List<String> _parseLines(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  /// Save all lines to API and navigate to classify.
  /// Validates on click — if nothing to save, shows gentle feedback.
  Future<void> _navigateToClassify() async {
    if (_isSaving) return;

    final lines = _parseLines(_controller.text);
    final savedItems = ref.read(itemsProvider).valueOrNull ?? [];
    if (lines.isEmpty && savedItems.isEmpty) {
      // Nothing entered yet — gentle nudge, no crash
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
      debugPrint('[DumpInput] session is null — cannot save items');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('세션이 없어요. 처음부터 다시 시도해 주세요.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (lines.isEmpty) {
      // Nothing new to save, just navigate
      context.go('/classify');
      return;
    }

    setState(() => _isSaving = true);
    try {
      for (final text in lines) {
        await ref.read(itemsProvider.notifier).addItem(session.sessionId, text);
      }
      if (mounted) {
        _controller.clear();
        setState(() => _isSaving = false);
        context.go('/classify');
      }
    } catch (e) {
      if (mounted) {
        // Keep text on failure so user doesn't lose input
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
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsProvider);
    final savedItems = itemsState.valueOrNull ?? [];

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
            const SizedBox(height: 8),
            Text('오늘 남은 것들',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '머릿속에 남아 있는 걸 줄마다 적어보세요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '정리되지 않아도 괜찮습니다. 한 줄에 하나씩 내려놓으면 됩니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: AppTheme.secondaryText,
                  ),
            ),
            const SizedBox(height: 16),
            // Already saved items (from previous interaction or API)
            if (savedItems.isNotEmpty) ...[
              ...savedItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 14, color: AppTheme.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.content,
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.secondaryText)),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 24),
            ],
            // Multiline input area.
            // IMPORTANT for Korean IME stability on Windows:
            // - Explicit FocusNode prevents recreation on rebuild
            // - No onChanged, no ValueListenableBuilder, no controller listener
            // - No inputFormatters that could interfere with composition
            // - autofocus only requests focus once on mount
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                autofocus: true,
                enabled: !_isSaving,
                decoration: InputDecoration(
                  hintText: '내일 회의 준비\n보낼 이메일 정리\n프로젝트 방향 고민\n...',
                  hintMaxLines: 10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.border),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Button always enabled — validates on click only.
            // IMPORTANT: Do NOT use ValueListenableBuilder or onChanged with
            // TextEditingController. Listening to the controller causes widget
            // rebuilds during IME composition, which crashes Korean (한글) input
            // on Windows. The button stays enabled; empty-input is handled
            // gracefully in _navigateToClassify.
            ElevatedButton(
              onPressed: _isSaving ? null : _navigateToClassify,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('분류하기'),
            ),
          ],
        ),
      ),
    );
  }
}
