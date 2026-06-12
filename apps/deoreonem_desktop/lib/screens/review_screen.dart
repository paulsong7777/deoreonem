import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../models/item_model.dart';
import '../providers/api_provider.dart';
import '../providers/local_storage_provider.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';
import '../providers/summary_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<ItemModel>? _items;
  bool _isLoading = true;
  String? _error;

  static const Map<String, String> categoryLabels = {
    'TOMORROW': '내일',
    'THIS_WEEK': '이번 주',
    'WAITING': '대기 중',
    'MEMO': '메모',
    'WORRY_ONLY': '걱정만',
  };

  /// Categories visible in review (NOW and DROP are excluded)
  static const Set<String> _visibleCategories = {
    'TOMORROW',
    'THIS_WEEK',
    'WAITING',
    'MEMO',
    'WORRY_ONLY',
  };

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    final storage = ref.read(localStorageProvider);
    final sessionIds = storage.getRecentCompletedSessionIds();
    if (sessionIds.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = '저장된 세션이 없습니다.';
      });
      return;
    }

    final allItems = <ItemModel>[];
    final api = ref.read(apiServiceProvider);

    for (final sessionId in sessionIds) {
      try {
        final items = await api.getReview(sessionId);
        allItems.addAll(items);
      } catch (_) {
        // Skip sessions that fail to load — continue with others
      }
    }

    if (mounted) {
      setState(() {
        _items = allItems;
        _isLoading = false;
        if (allItems.isEmpty && sessionIds.isNotEmpty) {
          _error = '리뷰를 불러오는데 실패했어요.';
        }
      });
    }
  }

  bool _isStarting = false;

  Future<void> _startNewSession() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    ref.read(itemsProvider.notifier).reset();
    ref.read(summaryProvider.notifier).reset();

    try {
      await ref.read(sessionProvider.notifier).createSession();
      if (mounted) context.go('/dump');
    } catch (e) {
      if (mounted) {
        setState(() => _isStarting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('세션을 시작할 수 없어요. 다시 시도해 주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startNewSession,
                child: const Text('오늘 새로 덜어내기'),
              ),
            ],
          ),
        ),
      );
    }

    final items = (_items ?? [])
        .where((i) =>
            i.category != null && _visibleCategories.contains(i.category))
        .toList();
    if (items.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('리뷰할 항목이 없습니다.',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startNewSession,
                child: const Text('오늘 새로 덜어내기'),
              ),
            ],
          ),
        ),
      );
    }

    // Group items by category
    final grouped = <String, List<ItemModel>>{};
    for (final item in items) {
      final cat = item.category!;
      grouped.putIfAbsent(cat, () => []).add(item);
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('맡겨둔 것들',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '총 ${items.length}개의 항목',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: grouped.entries.map((entry) {
                  final label = categoryLabels[entry.key] ?? entry.key;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          label,
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
                                  style: const TextStyle(fontSize: 14)),
                              dense: true,
                              leading: item.isFirstAction
                                  ? const Icon(Icons.star,
                                      color: AppTheme.accent, size: 18)
                                  : null,
                            ),
                          )),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startNewSession,
              child: const Text('오늘 새로 덜어내기'),
            ),
          ],
        ),
      ),
    );
  }
}
