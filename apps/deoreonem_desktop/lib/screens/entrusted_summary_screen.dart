import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../design/app_tokens.dart';
import '../design/app_components.dart';
import '../providers/session_provider.dart';
import '../providers/summary_provider.dart';
import '../providers/api_provider.dart';
import '../providers/local_storage_provider.dart';
import '../services/diagnostics_log.dart';

class EntrustedSummaryScreen extends ConsumerStatefulWidget {
  const EntrustedSummaryScreen({super.key});

  @override
  ConsumerState<EntrustedSummaryScreen> createState() =>
      _EntrustedSummaryScreenState();
}

class _EntrustedSummaryScreenState
    extends ConsumerState<EntrustedSummaryScreen> {
  bool _isCompleting = false;

  static const Map<String, String> categoryLabels = {
    'NOW': '지금',
    'TOMORROW': '내일',
    'THIS_WEEK': '이번 주',
    'WAITING': '대기 중',
    'MEMO': '메모',
    'WORRY_ONLY': '걱정만 남은 것',
    'DROP': '남기지 않기',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(sessionProvider).valueOrNull;
      if (session != null) {
        ref.read(summaryProvider.notifier).loadSummary(session.sessionId);
      }
    });
  }

  Future<void> _completeSession() async {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _isCompleting = true);
    try {
      await ref.read(apiServiceProvider).completeSession(session.sessionId);

      // Local persistence — mandatory. If this fails, do NOT navigate away.
      final storage = ref.read(localStorageProvider);
      try {
        await storage.saveLastCompletedSession(
          session.sessionId,
          DateTime.now(),
        );
      } catch (e) {
        logDiagnostic('SESSION_COMPLETE_FAILED sessionId=${session.sessionId} error=$e');
        if (mounted) {
          setState(() => _isCompleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            CalmSnackBar.show('세션 저장에 실패했어요: $e'),
          );
        }
        return; // DO NOT navigate to /complete
      }

      logDiagnostic('SESSION_COMPLETE sessionId=${session.sessionId} ids=${storage.getRecentCompletedSessionIds()} fileWriteSuccess=true');

      // Cache reviewable count for StartScreen
      final summary = ref.read(summaryProvider).valueOrNull;
      if (summary != null) {
        final reviewableCount = summary.itemsByCategory.entries
            .where((e) => ['TOMORROW', 'THIS_WEEK', 'WAITING', 'MEMO', 'WORRY_ONLY'].contains(e.key))
            .fold<int>(0, (sum, e) => sum + e.value.length);
        await storage.setReviewableEntrustedCount(reviewableCount);
      }
      if (mounted) context.go('/complete');
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          CalmSnackBar.show('$e'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(summaryProvider);

    return Scaffold(
      body: summaryState.when(
        loading: () => Center(child: CircularProgressIndicator(color: AppTokens.sagePrimary)),
        error: (e, _) => Center(
          child: Padding(
            padding: AppTokens.pagePadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('요약을 불러오는데 실패했어요.', style: AppTokens.body),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      final session = ref.read(sessionProvider).valueOrNull;
                      if (session != null) {
                        ref
                            .read(summaryProvider.notifier)
                            .loadSummary(session.sessionId);
                      }
                    },
                    child: const Text('다시 시도'),
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (summary) {
          if (summary == null) {
            return Center(child: CircularProgressIndicator(color: AppTokens.sagePrimary));
          }

          return Padding(
            padding: AppTokens.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('잘 맡겨두었어요', style: AppTokens.heading),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => context.go('/first-action'),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios, size: 14, color: AppTokens.textSecondary),
                      const SizedBox(width: 4),
                      Text('돌아가기', style: AppTokens.label),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // First Action highlight
                if (summary.firstActionItem != null) ...[
                  ProductSurface(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: AppTokens.sagePrimary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '내일 가장 먼저 볼 것',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTokens.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                summary.firstActionItem!.content,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500, color: AppTokens.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  '총 ${summary.totalItems}개를 맡겼습니다.',
                  style: AppTokens.body,
                ),
                // Worry soft-fade notice
                if ((summary.itemsByCategory['WORRY_ONLY'] ?? []).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '걱정으로 맡겨둔 것 ${summary.itemsByCategory['WORRY_ONLY']!.length}개',
                    style: AppTokens.label,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '이 걱정은 3일 뒤 조용히 사라집니다. 지금 해결하지 않아도 괜찮아요.',
                    style: AppTokens.bodyMuted,
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: summary.itemsByCategory.entries
                        .where((e) => e.value.isNotEmpty)
                        .map((entry) => Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    categoryLabels[entry.key] ?? entry.key,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTokens.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                ...entry.value.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: ProductSurface(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    child: Row(
                                      children: [
                                        if (item.isFirstAction)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Icon(Icons.star,
                                                size: 16,
                                                color: AppTokens.sagePrimary),
                                          ),
                                        Expanded(
                                          child: Text(item.content,
                                              style: const TextStyle(fontSize: 14, color: AppTokens.textPrimary)),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                              ],
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isCompleting ? null : _completeSession,
                    child: _isCompleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text('완료하기', style: AppTokens.buttonPrimary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
