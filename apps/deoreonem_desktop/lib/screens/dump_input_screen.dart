import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';
import '../theme.dart';
import '../design/app_tokens.dart';
import '../design/app_components.dart';

// KOREAN IME STABILITY RULE:
// The TextField must NEVER be rebuilt by parent state changes during typing.
// Korean syllable composition (받침 → 모음 transitions) is interrupted if
// the widget tree above the TextField rebuilds. This isolated widget ensures
// no provider state, savedItems list, or error state can trigger a rebuild
// that disrupts IME composition.

class DumpInputScreen extends ConsumerStatefulWidget {
  const DumpInputScreen({super.key});

  @override
  ConsumerState<DumpInputScreen> createState() => _DumpInputScreenState();
}

class _DumpInputScreenState extends ConsumerState<DumpInputScreen> {
  final GlobalKey<_StableTextInputState> _inputKey = GlobalKey<_StableTextInputState>();
  bool _isSaving = false;

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

    final text = _inputKey.currentState?.text ?? '';
    final lines = _parseLines(text);
    final savedItems = ref.read(itemsProvider).valueOrNull ?? [];
    if (lines.isEmpty && savedItems.isEmpty) {
      // Nothing entered yet — gentle nudge, no crash
      ScaffoldMessenger.of(context).showSnackBar(
        CalmSnackBar.show('적어놓은 내용이 없어요.'),
      );
      return;
    }

    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) {
      debugPrint('[DumpInput] session is null — cannot save items');
      ScaffoldMessenger.of(context).showSnackBar(
        CalmSnackBar.show('세션이 없어요. 처음부터 다시 시도해 주세요.'),
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
        _inputKey.currentState?.clear();
        setState(() => _isSaving = false);
        context.go('/classify');
      }
    } catch (e) {
      if (mounted) {
        // Keep text on failure so user doesn't lose input
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          CalmSnackBar.show('저장에 실패했어요: $e'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsProvider);
    final savedItems = itemsState.valueOrNull ?? [];

    return Scaffold(
      body: Padding(
        padding: AppTokens.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.go('/'),
              child: Row(
                children: [
                  Icon(Icons.home_outlined, size: 16, color: AppTokens.textSecondary),
                  const SizedBox(width: 4),
                  Text('처음으로', style: AppTokens.label),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('마음속에 담긴 것을 적어주세요.', style: AppTokens.heading),
            const SizedBox(height: 8),
            Text(
              '정리되지 않아도 괜찮습니다. 한 줄에 하나씩 내려놓으면 됩니다.',
              style: AppTokens.body,
            ),
            const SizedBox(height: 20),
            // Already saved items (from previous interaction or API)
            if (savedItems.isNotEmpty) ...[
              ...savedItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 14, color: AppTokens.sagePrimary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item.content,
                              style: TextStyle(
                                  fontSize: 13, color: AppTokens.textSecondary)),
                        ),
                      ],
                    ),
                  )),
              Divider(height: 28, color: AppTokens.borderWarm),
            ],
            // Isolated TextField — NEVER rebuilt by provider state changes.
            // See _StableTextInput class and KOREAN IME STABILITY RULE above.
            Expanded(
              child: _StableTextInput(
                key: _inputKey,
                isSaving: _isSaving,
                onSubmit: (_) => _navigateToClassify(),
              ),
            ),
            const SizedBox(height: 20),
            // Button always enabled — validates on click only.
            // IMPORTANT: Do NOT use ValueListenableBuilder or onChanged with
            // TextEditingController. Listening to the controller causes widget
            // rebuilds during IME composition, which crashes Korean (한글) input
            // on Windows. The button stays enabled; empty-input is handled
            // gracefully in _navigateToClassify.
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _navigateToClassify,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text('분류하기', style: AppTokens.buttonPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Isolated text input widget — NEVER rebuilt by provider state changes.
/// This prevents Korean IME composition from being interrupted.
class _StableTextInput extends StatefulWidget {
  final bool isSaving;
  final ValueChanged<String> onSubmit;

  const _StableTextInput({
    super.key,
    required this.isSaving,
    required this.onSubmit,
  });

  @override
  State<_StableTextInput> createState() => _StableTextInputState();
}

class _StableTextInputState extends State<_StableTextInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get text => _controller.text;

  void clear() => _controller.clear();

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      autofocus: true,
      enabled: !widget.isSaving,
      // NO onChanged, NO onSubmitted, NO inputFormatters
      // NO keyboard shortcuts that intercept during composition
      decoration: InputDecoration(
        hintText: '내일 회의 준비\n보낼 이메일 정리\n프로젝트 방향 고민\n...',
        hintMaxLines: 10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: BorderSide(color: AppTokens.borderWarm),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
