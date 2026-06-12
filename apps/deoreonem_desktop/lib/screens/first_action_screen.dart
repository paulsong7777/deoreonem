import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';
import '../providers/api_provider.dart';

class FirstActionScreen extends ConsumerStatefulWidget {
  const FirstActionScreen({super.key});

  @override
  ConsumerState<FirstActionScreen> createState() => _FirstActionScreenState();
}

class _FirstActionScreenState extends ConsumerState<FirstActionScreen> {
  int? _selectedIndex;
  bool _isSaving = false;

  Future<void> _setFirstAction() async {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null || _selectedIndex == null) return;

    final eligible = ref.read(itemsProvider.notifier).eligibleForFirstAction;
    if (_selectedIndex! >= eligible.length) return;

    final item = eligible[_selectedIndex!];
    setState(() => _isSaving = true);

    try {
      await ref
          .read(apiServiceProvider)
          .setFirstAction(session.sessionId, item.itemId);
      if (mounted) context.go('/summary');
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsProvider);
    final eligible = ref.read(itemsProvider.notifier).eligibleForFirstAction;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('첫 번째 할 일',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => context.go('/classify'),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: 14, color: AppTheme.secondaryText),
                  const SizedBox(width: 4),
                  Text('돌아가기', style: TextStyle(fontSize: 12, color: AppTheme.secondaryText)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '내일 가장 먼저 할 일 하나를 고르세요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: itemsState.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('오류: $e')),
                data: (_) => eligible.isEmpty
                    ? Center(
                        child: Text(
                          '내일로 분류된 항목이 없습니다.\n건너뛰기를 눌러 계속하세요.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                  itemCount: eligible.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedIndex == index;
                    return Card(
                      color: isSelected
                          ? AppTheme.accent.withValues(alpha: 0.1)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color:
                              isSelected ? AppTheme.accent : AppTheme.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(eligible[index].content),
                        leading: Radio<int>(
                          value: index,
                          groupValue: _selectedIndex,
                          onChanged: _isSaving
                              ? null
                              : (val) =>
                                  setState(() => _selectedIndex = val),
                          activeColor: AppTheme.accent,
                        ),
                        onTap: _isSaving
                            ? null
                            : () => setState(() => _selectedIndex = index),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => context.go('/summary'),
                    child: const Text('건너뛰기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (_selectedIndex != null && !_isSaving)
                            ? _setFirstAction
                            : null,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('다음'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
