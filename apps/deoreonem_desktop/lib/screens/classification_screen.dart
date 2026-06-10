import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class ClassificationScreen extends StatefulWidget {
  const ClassificationScreen({super.key});

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  // Mock items for Phase 3 (static UI only)
  final List<String> _items = [
    'API 설계 마저 하기',
    '리뷰 요청 답변 보내기',
    '프로젝트 방향 맞는 걸까',
  ];
  final List<String?> _categories = [null, null, null];
  int _currentIndex = 0;

  static const List<Map<String, String>> categoryButtons = [
    {'key': 'NOW', 'label': '지금', 'desc': '오늘 안에 반드시'},
    {'key': 'TOMORROW', 'label': '내일', 'desc': '내일 첫 번째로'},
    {'key': 'THIS_WEEK', 'label': '이번 주', 'desc': '이번 주 안에'},
    {'key': 'WAITING', 'label': '대기 중', 'desc': '누군가를 기다리는 중'},
    {'key': 'MEMO', 'label': '메모', 'desc': '기억해두기'},
    {'key': 'WORRY_ONLY', 'label': '걱정만', 'desc': '지금은 어쩔 수 없는 걱정'},
    {'key': 'DROP', 'label': '버리기', 'desc': '내려놓기'},
  ];

  int get _classifiedCount => _categories.where((c) => c != null).length;

  void _classify(String category) {
    setState(() {
      _categories[_currentIndex] = category;
      if (_currentIndex < _items.length - 1) {
        _currentIndex++;
      }
    });
  }

  bool get _allClassified => _classifiedCount == _items.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('분류하기', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '$_classifiedCount / ${_items.length} 분류됨',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            // Current item card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    _items[_currentIndex],
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Category buttons
            Expanded(
              child: ListView.separated(
                itemCount: categoryButtons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cat = categoryButtons[index];
                  final isDropCategory = cat['key'] == 'DROP';
                  return OutlinedButton(
                    onPressed:
                        _allClassified ? null : () => _classify(cat['key']!),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          isDropCategory ? AppTheme.drop : AppTheme.primaryText,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Row(
                      children: [
                        Text(cat['label']!,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Text(cat['desc']!,
                            style: TextStyle(
                                color: AppTheme.secondaryText, fontSize: 13)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  _allClassified ? () => context.go('/first-action') : null,
              child: const Text('다음'),
            ),
          ],
        ),
      ),
    );
  }
}
