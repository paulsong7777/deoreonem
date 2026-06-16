import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';
import '../theme.dart';

// KOREAN IME STABILITY RULE:
// The TextField must NEVER be rebuilt by parent state changes during typing.
// Korean syllable composition (받침 → 모음 transitions) is interrupted if
// the widget tree changes layout above or around the TextField.
//
// Critical rules:
// 1. Do NOT use ref.watch in the build method — it triggers rebuilds.
// 2. Do NOT render dynamic content (like savedItems list) in the same
//    Column as the TextField — layout shifts disrupt IME.
// 3. The TextField widget must be in a FIXED layout position that never
//    changes size or position during typing.

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
    // Request focus after first frame — avoids autofocus race with IME initialization
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

  /// Parse multiline text into non-empty trimmed lines
  List<String> _parseLines(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<void> _navigateToClassify() async {
    if (_isSaving) return;

    final lines = _parseLines(_controller.text);
    final savedItems = ref.read(itemsProvider).valueOrNull ?? [];
    if (lines.isEmpty && savedItems.isEmpty) {
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

    if (lines.isEmpty) {
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
    // CRITICAL: No ref.watch here. No provider-dependent content in this Column.
    // The layout is STATIC during typing — nothing above the TextField changes.
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
            // FIXED-SIZE text input area. No dynamic savedItems list above.
            // The TextField position/size never changes during typing.
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                // NO autofocus — focus requested via postFrameCallback to avoid
                // race condition with Windows IME initialization.
                // enableIMEPersonalizedLearning disabled to prevent Windows IME
                // from interfering with composition state.
                enableIMEPersonalizedLearning: false,
                enableSuggestions: false,
                autocorrect: false,
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
