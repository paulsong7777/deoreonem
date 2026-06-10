import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class EntrustedSummaryScreen extends StatelessWidget {
  const EntrustedSummaryScreen({super.key});

  // Mock summary data
  static const Map<String, List<String>> mockItemsByCategory = {
    'NOW': ['API 설계 마저 하기'],
    'TOMORROW': ['리뷰 요청 답변 보내기'],
    'THIS_WEEK': [],
    'WAITING': [],
    'MEMO': [],
    'WORRY_ONLY': ['프로젝트 방향 맞는 걸까'],
    'DROP': [],
  };

  static const Map<String, String> categoryLabels = {
    'NOW': '지금',
    'TOMORROW': '내일',
    'THIS_WEEK': '이번 주',
    'WAITING': '대기 중',
    'MEMO': '메모',
    'WORRY_ONLY': '걱정만',
    'DROP': '버리기',
  };

  int get _totalItems =>
      mockItemsByCategory.values.fold(0, (sum, list) => sum + list.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오늘의 덜어냄',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            // First Action highlight
            Card(
              color: AppTheme.accent.withValues(alpha: 0.08),
              child: const ListTile(
                leading: Icon(Icons.star, color: AppTheme.accent),
                title: Text('API 설계 마저 하기'),
                subtitle: Text('내일 가장 먼저'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '총 ${_totalItems}개를 맡겼습니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: mockItemsByCategory.entries
                    .where((e) => e.value.isNotEmpty)
                    .map((entry) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
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
                                    title: Text(item,
                                        style: const TextStyle(fontSize: 14)),
                                    dense: true,
                                  ),
                                )),
                          ],
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/complete'),
              child: const Text('완료하기'),
            ),
          ],
        ),
      ),
    );
  }
}
