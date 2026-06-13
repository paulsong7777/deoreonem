import 'dart:io';

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

enum _ReviewState { loading, error, items, entrusted, empty }

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  List<ItemModel> _items = [];
  _ReviewState _state = _ReviewState.loading;
  String? _errorMessage;
  final Set<String> _removingIds = {};
  bool _isStarting = false;
  bool _hasConvertedWorryToNutrient = false;

  static const Map<String, String> categoryLabels = {
    'TOMORROW': '내일 다시 볼 것',
    'THIS_WEEK': '이번 주 안에 볼 것',
    'WAITING': '기다리는 것',
    'MEMO': '기록만 남긴 것',
    'WORRY_ONLY': '걱정만 남은 것',
  };

  static const Map<String, String> _drawerLabels = {
    'TOMORROW': '일정 서랍',
    'THIS_WEEK': '일정 서랍',
    'WAITING': '일정 서랍',
    'MEMO': '메모 서랍',
    'WORRY_ONLY': '감정 서랍',
  };

  static const List<String> _categoryOrder = [
    'TOMORROW', 'THIS_WEEK', 'WAITING', 'MEMO', 'WORRY_ONLY',
  ];

  static const Set<String> _visibleCategories = {
    'TOMORROW', 'THIS_WEEK', 'WAITING', 'MEMO', 'WORRY_ONLY',
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
        _state = _ReviewState.error;
        _errorMessage = '저장된 세션이 없습니다.';
      });
      return;
    }

    final allItems = <ItemModel>[];
    final api = ref.read(apiServiceProvider);

    for (final sessionId in sessionIds) {
      try {
        final items = await api.getReview(sessionId);
        allItems.addAll(items);
      } catch (_) {}
    }

    if (mounted) {
      if (allItems.isEmpty) {
        setState(() {
          _state = _ReviewState.error;
          _errorMessage = '리뷰를 불러오는데 실패했어요.';
        });
      } else {
        final visible = allItems
            .where((i) => i.category != null && _visibleCategories.contains(i.category))
            .toList();
        ref.read(localStorageProvider).setReviewableEntrustedCount(visible.length);
        setState(() {
          _items = allItems;
          _state = _ReviewState.items;
        });
      }
    }
  }

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

  void _keepItem(ItemModel item, String message) {
    // No backend call — just show a calm SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _closeItem(ItemModel item) async {
    if (_removingIds.contains(item.itemId)) return;
    setState(() => _removingIds.add(item.itemId));
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateCategory(item.sessionId, item.itemId, 'DROP');
      if (mounted) {
        setState(() {
          _items.removeWhere((i) => i.itemId == item.itemId);
          _removingIds.remove(item.itemId);
          final visible = _items.where((i) => i.category != null && _visibleCategories.contains(i.category)).toList();
          ref.read(localStorageProvider).setReviewableEntrustedCount(visible.length);
          if (visible.isEmpty) _state = _ReviewState.empty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _removingIds.remove(item.itemId));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('처리할 수 없어요. 다시 시도해 주세요.')));
      }
    }
  }

  Future<void> _letGoWorry(ItemModel item) async {
    if (_removingIds.contains(item.itemId)) return;
    setState(() => _removingIds.add(item.itemId));
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateCategory(item.sessionId, item.itemId, 'DROP');
      if (mounted) {
        setState(() {
          _items.removeWhere((i) => i.itemId == item.itemId);
          _removingIds.remove(item.itemId);
          _hasConvertedWorryToNutrient = true;
          final visible = _items.where((i) => i.category != null && _visibleCategories.contains(i.category)).toList();
          ref.read(localStorageProvider).setReviewableEntrustedCount(visible.length);
          if (visible.isEmpty) _state = _ReviewState.empty;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('걱정 하나가 작은 양분이 되었습니다.'), duration: Duration(seconds: 3)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _removingIds.remove(item.itemId));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('처리할 수 없어요. 다시 시도해 주세요.')));
      }
    }
  }

  void _keepEntrusted() {
    setState(() => _state = _ReviewState.entrusted);
  }

  void _closeApp() {
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _ReviewState.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case _ReviewState.error:
        return _buildErrorView(context);

      case _ReviewState.empty:
        return _buildEmptyView(context);

      case _ReviewState.entrusted:
        return _buildEntrustedView(context);

      case _ReviewState.items:
        return _buildItemsView(context);
    }
  }

  Widget _buildErrorView(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage ?? '', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startNewSession,
              child: const Text('새로 비우기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                '지금 다시 꺼내볼 것은 없습니다.',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_hasConvertedWorryToNutrient) ...[
                const SizedBox(height: 8),
                Text(
                  '사라진 것이 아니라, 오늘의 쉼을 위한 작은 양분이 되었습니다.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const SizedBox(height: 8),
                Text(
                  '방금 닫아둔 생각들은 여기서 조용히 정리되었습니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '필요하면 새로 비워내고, 아니면 이대로 마쳐도 괜찮습니다.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isStarting ? null : _startNewSession,
                child: _isStarting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('새로 비우기'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _closeApp,
                child: const Text('창 닫기',
                    style: TextStyle(color: AppTheme.secondaryText, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntrustedView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                '그대로 두어도 괜찮습니다.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                '지금 다시 붙잡지 않아도 됩니다.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '맡겨둔 것들은 여기 그대로 남아 있어요.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '필요할 때 다시 꺼내보면 됩니다.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isStarting ? null : _startNewSession,
                child: _isStarting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('새로 비우기'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _closeApp,
                child: const Text('창 닫기',
                    style: TextStyle(color: AppTheme.secondaryText, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _entrustedLabel(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays == 0) return '오늘 맡김';
    if (diff.inDays == 1) return '어제 맡김';
    if (diff.inDays < 7) return '${diff.inDays}일 전 맡김';
    return '${createdAt.month}월 ${createdAt.day}일 맡김';
  }

  Widget _buildItemsView(BuildContext context) {
    final items = _items
        .where((i) => i.category != null && _visibleCategories.contains(i.category))
        .toList();

    if (items.isEmpty) {
      // Transition to empty state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _state = _ReviewState.empty);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            Text('잠시 맡겨둔 서랍',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '일정은 일정 서랍에, 걱정은 감정 서랍에 잠시 맡겨두었습니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '지금 다시 볼 것만 확인하고, 나머지는 그대로 두어도 괜찮습니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: _categoryOrder
                    .where((cat) => grouped.containsKey(cat))
                    .map((cat) {
                  final label = categoryLabels[cat] ?? cat;
                  final drawerLabel = _drawerLabels[cat] ?? '';
                  final groupItems = grouped[cat]!;
                  final isWorry = cat == 'WORRY_ONLY';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text(label,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.secondaryText,
                                    fontSize: 13)),
                            if (drawerLabel.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(drawerLabel,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.secondaryText.withOpacity(0.7))),
                            ],
                          ],
                        ),
                      ),
                      ...groupItems.map((item) {
                        final isMemo = cat == 'MEMO';
                        final isSchedule = cat == 'TOMORROW' || cat == 'THIS_WEEK' || cat == 'WAITING';
                        return Card(
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              title: Text(item.content,
                                  style: const TextStyle(fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_entrustedLabel(item.createdAt),
                                      style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
                                  if (isWorry) ...[
                                    const SizedBox(height: 4),
                                    Text('이 걱정은 3일 뒤 조용히 사라집니다.\n지금 해결하지 않아도 괜찮아요.',
                                        style: TextStyle(fontSize: 11, color: AppTheme.secondaryText, height: 1.4)),
                                  ],
                                ],
                              ),
                              dense: true,
                              trailing: _removingIds.contains(item.itemId)
                                  ? const SizedBox(width: 16, height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2))
                                  : isSchedule
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextButton(
                                              onPressed: () => _keepItem(item, '일정 서랍에 그대로 두었습니다.'),
                                              child: Text('나중에 보기', style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
                                            ),
                                            TextButton(
                                              onPressed: () => _closeItem(item),
                                              child: Text('오늘은 닫기', style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
                                            ),
                                          ],
                                        )
                                      : isMemo
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextButton(
                                                  onPressed: () => _keepItem(item, '메모 서랍에 조용히 보관했습니다.'),
                                                  child: Text('보관하기', style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
                                                ),
                                                TextButton(
                                                  onPressed: () => _closeItem(item),
                                                  child: Text('닫기', style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextButton(
                                                  onPressed: () => _keepItem(item, '감정 서랍에 조금 더 맡겨두었습니다.'),
                                                  child: Text('조금 더 맡겨두기', style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
                                                ),
                                                TextButton(
                                                  onPressed: () => _letGoWorry(item),
                                                  child: Text('이 걱정 내려놓기', style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
                                                ),
                                              ],
                                            ),
                            ),
                          );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isStarting ? null : _startNewSession,
              child: _isStarting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('새로 비우기'),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _keepEntrusted,
                child: const Text('그대로 두기',
                    style: TextStyle(color: AppTheme.secondaryText, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
