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
  String _selectedDrawer = '감정'; // Default drawer tab

  static const Map<String, String> categoryLabels = {
    'TOMORROW': '내일 다시 볼 것',
    'THIS_WEEK': '이번 주 안에 볼 것',
    'WAITING': '기다리는 것',
    'MEMO': '기록만 남긴 것',
    'WORRY_ONLY': '걱정만 남은 것',
  };

  static const Map<String, List<String>> _drawerCategories = {
    '일정': ['TOMORROW', 'THIS_WEEK', 'WAITING'],
    '메모': ['MEMO'],
    '감정': ['WORRY_ONLY'],
  };

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

        // Set default drawer based on content
        final hasWorry = visible.any((i) => i.category == 'WORRY_ONLY');
        final hasSchedule = visible.any((i) => ['TOMORROW', 'THIS_WEEK', 'WAITING'].contains(i.category));
        final hasMemo = visible.any((i) => i.category == 'MEMO');

        String defaultDrawer = '감정';
        if (hasWorry) {
          defaultDrawer = '감정';
        } else if (hasSchedule) {
          defaultDrawer = '일정';
        } else if (hasMemo) {
          defaultDrawer = '메모';
        }

        setState(() {
          _items = allItems;
          _state = _ReviewState.items;
          _selectedDrawer = defaultDrawer;
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

  Future<void> _resetWorryFade(ItemModel item) async {
    await ref.read(localStorageProvider).resetWorryFade(item.itemId);
    setState(() {}); // Refresh fade labels
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('감정 서랍에 다시 3일 맡겨두었습니다.'), duration: Duration(seconds: 2)),
      );
    }
  }

  String _worryFadeLabel(ItemModel item) {
    final storage = ref.read(localStorageProvider);
    final resets = storage.getWorryFadeResets();
    final baseTime = resets[item.itemId] ?? item.createdAt;
    final fadeAt = baseTime.add(const Duration(days: 3));
    final now = DateTime.now();
    final remaining = fadeAt.difference(now);

    if (remaining.inDays >= 3) return '3일 뒤 흐려짐';
    if (remaining.inDays == 2) return '2일 뒤 흐려짐';
    if (remaining.inDays == 1) return '내일쯤 흐려짐';
    if (remaining.isNegative) return '흐려지는 중';
    return '오늘 조용히 흐려짐';
  }

  void _keepEntrusted() {
    setState(() => _state = _ReviewState.entrusted);
  }

  void _closeApp() {
    exit(0);
  }

  int _getCountForDrawer(String drawer, Map<String, List<ItemModel>> grouped) {
    final categories = _drawerCategories[drawer] ?? [];
    int count = 0;
    for (final cat in categories) {
      count += grouped[cat]?.length ?? 0;
    }
    return count;
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

  Widget _buildItemCard(BuildContext context, ItemModel item, {required bool isWorry, required bool isMemo, required bool isSchedule}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.content, style: const TextStyle(fontSize: 14)),
            if (isWorry) ...[
              const SizedBox(height: 4),
              Text(_worryFadeLabel(item),
                  style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
            ] else ...[
              const SizedBox(height: 4),
              Text(_entrustedLabel(item.createdAt),
                  style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
            ],
            const SizedBox(height: 4),
            if (_removingIds.contains(item.itemId))
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              _buildActions(item, isWorry: isWorry, isMemo: isMemo, isSchedule: isSchedule),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(ItemModel item, {required bool isWorry, required bool isMemo, required bool isSchedule}) {
    if (isSchedule) {
      // Single action: "확인했어요" — closes item, no nutrient shown
      return Row(
        children: [
          TextButton(
            onPressed: () => _closeItem(item),
            child: Text('확인했어요',
                style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
          ),
        ],
      );
    }
    if (isMemo) {
      // Single action: "보관하기" — closes item
      // TODO: Future — link to notebook feature
      return Row(
        children: [
          TextButton(
            onPressed: () => _closeItem(item),
            child: Text('보관하기',
                style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
          ),
        ],
      );
    }
    // Worry — two actions
    return Row(
      children: [
        TextButton(
          onPressed: () => _letGoWorry(item),
          child: Text('이 걱정 내려놓기',
              style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
        ),
        TextButton(
          onPressed: () => _resetWorryFade(item),
          child: Text('다시 3일 맡겨두기',
              style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
        ),
      ],
    );
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
              '필요한 서랍만 열어 확인합니다.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Drawer tab selector
            _buildDrawerTabs(grouped),
            const SizedBox(height: 16),
            // Drawer content
            Expanded(
              child: _buildDrawerContent(grouped),
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

  Widget _buildDrawerTabs(Map<String, List<ItemModel>> grouped) {
    return Row(
      children: ['일정', '메모', '감정'].map((tab) {
        final count = _getCountForDrawer(tab, grouped);
        final isSelected = _selectedDrawer == tab;
        return Expanded(
          child: GestureDetector(
            onTap: count > 0 ? () => setState(() => _selectedDrawer = tab) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppTheme.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                '$tab $count',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppTheme.primaryText : AppTheme.secondaryText,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDrawerContent(Map<String, List<ItemModel>> grouped) {
    final categories = _drawerCategories[_selectedDrawer] ?? [];
    final isWorryDrawer = _selectedDrawer == '감정';
    final isMemoDrawer = _selectedDrawer == '메모';
    final isScheduleDrawer = _selectedDrawer == '일정';

    final drawerItems = <ItemModel>[];
    for (final cat in categories) {
      drawerItems.addAll(grouped[cat] ?? []);
    }

    if (drawerItems.isEmpty) {
      return Center(
        child: Text(
          '이 서랍은 비어 있습니다.',
          style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
        ),
      );
    }

    return ListView(
      children: [
        // Emotion drawer header
        if (isWorryDrawer)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '걱정은 시간이 지나면 조용히 흐려집니다. 지금 해결하지 않아도 괜찮아요.',
              style: TextStyle(fontSize: 12, color: AppTheme.secondaryText, height: 1.4),
            ),
          ),
        ...drawerItems.map((item) => _buildItemCard(
          context,
          item,
          isWorry: isWorryDrawer,
          isMemo: isMemoDrawer,
          isSchedule: isScheduleDrawer,
        )),
      ],
    );
  }
}
