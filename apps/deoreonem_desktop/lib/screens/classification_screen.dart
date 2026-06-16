import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../design/app_tokens.dart';
import '../design/app_components.dart';
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
      } catch (e) {
        if (mounted) {
          setState(() => _isClassifying = false);
          _showClassifyError(e);
        }
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
    } catch (e) {
      if (mounted) {
        setState(() => _isClassifying = false);
        _showClassifyError(e);
      }
    }
  }

  void _showClassifyError([Object? error]) {
    ScaffoldMessenger.of(context).showSnackBar(
      CalmSnackBar.show(error != null
          ? '분류를 저장하지 못했어요: $error'
          : '분류를 저장하지 못했어요. 다시 시도해 주세요.'),
    );
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
          padding: AppTokens.pagePadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('분류할 항목이 없습니다.',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => context.go('/dump'),
                  child: const Text('돌아가기'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: AppTokens.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('분류하기', style: AppTokens.titleScreen),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/dump'),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back_ios, size: 14, color: AppTokens.textSecondary),
                      const SizedBox(width: 4),
                      Text('돌아가기', style: AppTokens.label),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (_classifiedItemIds.isNotEmpty && !isReviewing)
                  GestureDetector(
                    onTap: () => _goToPreviousItem(items),
                    child: Text('직전 항목 수정',
                        style: TextStyle(fontSize: 12, color: AppTokens.textSecondary)),
                  ),
                const Spacer(),
                Text(
                  '$classifiedCount / ${items.length} 분류됨',
                  style: AppTokens.label,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Current item card
            if (currentItem != null)
              ProductSurface(
                width: double.infinity,
                child: Text(
                  currentItem.content,
                  style: const TextStyle(fontSize: 15, color: AppTokens.textPrimary, height: 1.5),
                ),
              ),
            const SizedBox(height: 20),
            // Minimal worry helper
            Text(
              '걱정은 맡겨두면 3일 뒤 조용히 사라집니다.',
              style: TextStyle(fontSize: 10, color: AppTokens.textMuted.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            // Category buttons
            Expanded(
              child: _isClassifying
                  ? Center(child: CircularProgressIndicator(color: AppTokens.sagePrimary))
                  : ListView(
                      children: _categoryGroups.expand((group) {
                        final drawer = group['drawer'] as String;
                        final catItems = (group['items'] as List).cast<Map<String, String>>();
                        return [
                          if (drawer.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 6),
                              child: Text(drawer,
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: AppTokens.textMuted.withOpacity(0.6))),
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
                                      : AppTokens.textPrimary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  alignment: Alignment.centerLeft,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTokens.radiusButton),
                                  ),
                                  side: isCurrentCategory
                                      ? BorderSide(color: AppTokens.sagePrimary, width: 2)
                                      : BorderSide(color: AppTokens.borderWarm),
                                  backgroundColor: isCurrentCategory
                                      ? AppTokens.sagePrimary.withOpacity(0.06)
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
                                              color: AppTokens.textSecondary,
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
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed:
                    allClassified ? () => context.go('/first-action') : null,
                child: Text('다음', style: AppTokens.buttonPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
