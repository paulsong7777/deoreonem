import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';
import '../models/item_model.dart';

class ClassificationScreen extends ConsumerStatefulWidget {
  const ClassificationScreen({super.key});

  @override
  ConsumerState<ClassificationScreen> createState() =>
      _ClassificationScreenState();
}

class _ClassificationScreenState extends ConsumerState<ClassificationScreen> {
  bool _isClassifying = false;
  final List<String> _classifiedItemIds = [];
  String? _reviewingItemId;

  static const List<Map<String, String>> categoryButtons = [
    {'key': 'NOW', 'label': '지금', 'desc': '오늘 안에 반드시'},
    {'key': 'TOMORROW', 'label': '내일', 'desc': '내일 첫 번째로'},
    {'key': 'THIS_WEEK', 'label': '이번 주', 'desc': '이번 주 안에'},
    {'key': 'WAITING', 'label': '대기 중', 'desc': '기다리는 중'},
    {'key': 'MEMO', 'label': '메모', 'desc': '기억해두기'},
    {'key': 'WORRY_ONLY', 'label': '걱정만', 'desc': '3일 뒤 조용히 사라질 걱정'},
    {'key': 'DROP', 'label': '바로 흘려보내기', 'desc': '서랍에 넣지 않고 지금은 흘려보냅니다.'},
  ];

  static const List<Map<String, dynamic>> _categoryGroups = [
    {
      'drawer': '일정 서랍',
      'items': [
        {'key': 'NOW', 'label': '지금', 'desc': '오늘 안에 반드시'},
        {'key': 'TOMORROW', 'label': '내일', 'desc': '내일 첫 번째로'},
        {'key': 'THIS_WEEK', 'label': '이번 주', 'desc': '이번 주 안에'},
        {'key': 'WAITING', 'label': '대기 중', 'desc': '기다리는 중'},
      ],
    },
    {
      'drawer': '메모 서랍',
      'items': [
        {'key': 'MEMO', 'label': '메모', 'desc': '기억해두기'},
      ],
    },
    {
      'drawer': '감정 서랍',
      'items': [
        {'key': 'WORRY_ONLY', 'label': '걱정만', 'desc': '3일 뒤 조용히 사라질 걱정'},
      ],
    },
    {
      'drawer': '',
      'items': [
        {'key': 'DROP', 'label': '바로 흘려보내기', 'desc': '서랍에 넣지 않고 지금은 흘려보냅니다.'},
      ],
    },
  ];

  Future<void> _classify(String category, List<ItemModel> items) async {
    if (_isClassifying || items.isEmpty) return;

    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    // If reviewing a previous item, reclassify it and return to forward flow
    if (_reviewingItemId != null) {
      final item = items.firstWhere((i) => i.itemId == _reviewingItemId, orElse: () => items.first);
      setState(() => _isClassifying = true);
      try {
        await ref
            .read(itemsProvider.notifier)
            .updateCategory(session.sessionId, item.itemId, category);
        if (mounted) {
          setState(() {
            _isClassifying = false;
            _reviewingItemId = null;
          });
          // Check if all classified
          final allItems = ref.read(itemsProvider).valueOrNull ?? [];
          final remaining = allItems.where((i) => i.category == null).toList();
          if (remaining.isEmpty && allItems.isNotEmpty) {
            context.go('/first-action');
          }
        }
      } catch (_) {
        if (mounted) setState(() => _isClassifying = false);
      }
      return;
    }

    final unclassified = items.where((i) => i.category == null).toList();
    if (unclassified.isEmpty) return;

    final item = unclassified.first;
    setState(() => _isClassifying = true);

    try {
      await ref
          .read(itemsProvider.notifier)
          .updateCategory(session.sessionId, item.itemId, category);

      if (mounted) {
        setState(() {
          _isClassifying = false;
          _classifiedItemIds.add(item.itemId);
        });

        // Auto-navigate if this was the last item
        final allItems = ref.read(itemsProvider).valueOrNull ?? [];
        final remaining = allItems.where((i) => i.category == null).toList();
        if (remaining.isEmpty && allItems.isNotEmpty) {
          context.go('/first-action');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isClassifying = false);
      }
    }
  }

  void _goToPreviousItem(List<ItemModel> items) {
    if (_classifiedItemIds.isEmpty) return;
    final lastId = _classifiedItemIds.last;
    setState(() => _reviewingItemId = lastId);
  }

  void _goToNextItem() {
    setState(() => _reviewingItemId = null);
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsProvider);
    final items = itemsState.valueOrNull ?? [];
    final unclassified = items.where((i) => i.category == null).toList();
    final classifiedCount = items.where((i) => i.category != null).length;
    final allClassified = unclassified.isEmpty && items.isNotEmpty;

    // Find the current item to display
    ItemModel? currentItem;
    bool isReviewing = false;
    if (_reviewingItemId != null) {
      currentItem = items.cast<ItemModel?>().firstWhere(
          (i) => i!.itemId == _reviewingItemId,
          orElse: () => null);
      isReviewing = currentItem != null;
    }
    if (currentItem == null) {
      if (unclassified.isNotEmpty) {
        currentItem = unclassified.first;
      } else if (items.isNotEmpty) {
        currentItem = items.last;
      }
    }

    if (items.isEmpty) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('분류할 항목이 없습니다.',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/dump'),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('분류하기', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/dump'),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios, size: 14, color: AppTheme.secondaryText),
                      const SizedBox(width: 4),
                      Text('돌아가기', style: TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (_classifiedItemIds.isNotEmpty && !isReviewing)
                  GestureDetector(
                    onTap: () => _goToPreviousItem(items),
                    child: Text('직전 항목 수정',
                        style: TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
                  ),
                const Spacer(),
                Text(
                  '$classifiedCount / ${items.length} 분류됨',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Current item card
            if (currentItem != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      currentItem.content,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Minimal worry helper
            Text(
              '걱정은 맡겨두면 3일 뒤 조용히 사라집니다.',
              style: TextStyle(fontSize: 10, color: AppTheme.secondaryText.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            // Category buttons
            Expanded(
              child: _isClassifying
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      children: _categoryGroups.expand((group) {
                        final drawer = group['drawer'] as String;
                        final catItems = (group['items'] as List).cast<Map<String, String>>();
                        return [
                          if (drawer.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 4),
                              child: Text(drawer,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.secondaryText)),
                            ),
                          ...catItems.map((cat) {
                            final isDropCategory = cat['key'] == 'DROP';
                            final isCurrentCategory = isReviewing &&
                                currentItem != null &&
                                currentItem.category == cat['key'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: OutlinedButton(
                                onPressed: (allClassified && !isReviewing)
                                    ? null
                                    : () => _classify(cat['key']!, items),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDropCategory
                                      ? AppTheme.drop
                                      : AppTheme.primaryText,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  alignment: Alignment.centerLeft,
                                  side: isCurrentCategory
                                      ? BorderSide(color: AppTheme.accent, width: 2)
                                      : null,
                                  backgroundColor: isCurrentCategory
                                      ? AppTheme.accent.withValues(alpha: 0.06)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Text(cat['label']!,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(cat['desc']!,
                                          style: TextStyle(
                                              color: AppTheme.secondaryText,
                                              fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ];
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  allClassified ? () => context.go('/first-action') : null,
              child: const Text('다음'),
            ),
          ],
        ),
      ),
    );
  }
}
