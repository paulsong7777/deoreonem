import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../providers/session_provider.dart';
import '../providers/summary_provider.dart';
import '../providers/api_provider.dart';
import '../providers/local_storage_provider.dart';

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
    'WORRY_ONLY': '걱정만',
    'DROP': '버리기',
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
      await ref.read(localStorageProvider).saveLastCompletedSession(
            session.sessionId,
            DateTime.now(),
          );
      if (mounted) context.go('/complete');
    } catch (e) {
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(summaryProvider);

    return Scaffold(
      body: summaryState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('요약을 불러오는데 실패했어요.'),
              const SizedBox(height: 16),
              ElevatedButton(
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
            ],
          ),
        ),
        data: (summary) {
          if (summary == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('오늘의 덜어냄',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context.go('/first-action'),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios, size: 14, color: AppTheme.secondaryText),
                      const SizedBox(width: 4),
                      Text('돌아가기', style: TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // First Action highlight — lighter design
                if (summary.firstActionItem != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.accent.withValues(alpha: 0.04),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppTheme.accent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '내일 가장 먼저 볼 것',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.secondaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                summary.firstActionItem!.content,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
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
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.secondaryText,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                ...entry.value.map((item) => Card(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      child: ListTile(
                                        title: Text(item.content,
                                            style:
                                                const TextStyle(fontSize: 14)),
                                        dense: true,
                                        leading: item.isFirstAction
                                            ? const Icon(Icons.star,
                                                size: 16,
                                                color: AppTheme.accent)
                                            : null,
                                      ),
                                    )),
                              ],
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isCompleting ? null : _completeSession,
                  child: _isCompleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('완료하기'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
