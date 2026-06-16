import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';
import '../theme.dart';

const _nativeInputChannel = MethodChannel('deoreonem/native_input');

class DumpInputScreen extends ConsumerStatefulWidget {
  const DumpInputScreen({super.key});

  @override
  ConsumerState<DumpInputScreen> createState() => _DumpInputScreenState();
}

class _DumpInputScreenState extends ConsumerState<DumpInputScreen> {
  final List<String> _pendingThoughts = [];
  bool _isSaving = false;

  Future<void> _openNativeInput() async {
    try {
      final result = await _nativeInputChannel.invokeMethod<String?>('openThoughtInput');
      if (result != null && result.trim().isNotEmpty) {
        setState(() {
          _pendingThoughts.add(result.trim());
        });
      }
    } on PlatformException catch (_) {
      // Native dialog not available — show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('입력 대화상자를 열 수 없어요.')),
        );
      }
    }
  }

  void _removeThought(int index) {
    setState(() {
      _pendingThoughts.removeAt(index);
    });
  }

  Future<void> _navigateToClassify() async {
    if (_isSaving) return;

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
            Text(
              '완벽히 정리하지 않아도 괜찮습니다. 떠오른 생각을 하나씩 적어두면 됩니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: AppTheme.secondaryText,
                  ),
            ),
            const SizedBox(height: 24),
            // Native input button — opens Win32 dialog for stable Korean IME
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _openNativeInput,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('생각 적기'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_pendingThoughts.isNotEmpty) ...[
              Text('방금 덜어낸 생각 (${_pendingThoughts.length}개)',
                  style: TextStyle(fontSize: 12, color: AppTheme.secondaryText, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: _pendingThoughts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb_outline, size: 32, color: AppTheme.secondaryText.withOpacity(0.3)),
                          const SizedBox(height: 8),
                          Text(
                            '"생각 적기"를 눌러 떠오르는 생각을 하나씩 적어주세요.',
                            style: TextStyle(fontSize: 13, color: AppTheme.secondaryText.withOpacity(0.6)),
                            textAlign: TextAlign.center,
                          ),
                        ],
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
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isSaving || _pendingThoughts.isEmpty) ? null : _navigateToClassify,
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
