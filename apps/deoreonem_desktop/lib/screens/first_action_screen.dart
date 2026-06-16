import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import '../design/app_tokens.dart';
import '../design/app_components.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';
import '../providers/api_provider.dart';
import '../providers/first_action_provider.dart';

class FirstActionScreen extends ConsumerStatefulWidget {
  const FirstActionScreen({super.key});

  @override
  ConsumerState<FirstActionScreen> createState() => _FirstActionScreenState();
}

class _FirstActionScreenState extends ConsumerState<FirstActionScreen> {
  int? _selectedIndex;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eligible = ref.read(itemsProvider.notifier).eligibleForFirstAction;
      // First try to restore from provider (persisted selection)
      final savedId = ref.read(firstActionSelectedIdProvider);
      if (savedId != null) {
        final savedIndex = eligible.indexWhere((i) => i.itemId == savedId);
        if (savedIndex >= 0) {
          setState(() => _selectedIndex = savedIndex);
          return;
        }
      }
      // Fall back to checking existing isFirstAction
      final existingIndex = eligible.indexWhere((i) => i.isFirstAction);
      if (existingIndex >= 0) {
        setState(() => _selectedIndex = existingIndex);
      }
    });
  }

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
      if (mounted) {
        ref.read(firstActionSelectedIdProvider.notifier).state = item.itemId;
        context.go('/summary');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          CalmSnackBar.show('$e'),
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
        padding: AppTokens.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이 일에 대해 지금 할 수 있는 행동은?', style: AppTokens.heading),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => context.go('/classify'),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios, size: 14, color: AppTokens.textSecondary),
                  const SizedBox(width: 4),
                  Text('돌아가기', style: AppTokens.label),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '내일 가장 먼저 할 일 하나를 고르세요.',
              style: AppTokens.body,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: itemsState.when(
                loading: () =>
                    Center(child: CircularProgressIndicator(color: AppTokens.sagePrimary)),
                error: (e, _) => Center(child: Text('오류: $e', style: AppTokens.body)),
                data: (_) => eligible.isEmpty
                    ? Center(
                        child: Text(
                          '내일로 분류된 항목이 없습니다.\n건너뛰기를 눌러 계속하세요.',
                          style: AppTokens.body,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                  itemCount: eligible.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: _isSaving
                            ? null
                            : () => setState(() => _selectedIndex = index),
                        child: ProductSurface(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                              border: isSelected
                                  ? Border.all(color: AppTokens.sagePrimary, width: 2)
                                  : null,
                              color: isSelected
                                  ? AppTokens.sagePrimary.withOpacity(0.05)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: index,
                                  groupValue: _selectedIndex,
                                  onChanged: _isSaving
                                      ? null
                                      : (val) =>
                                          setState(() => _selectedIndex = val),
                                  activeColor: AppTokens.sagePrimary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(eligible[index].content,
                                      style: const TextStyle(
                                          fontSize: 14, color: AppTokens.textPrimary)),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => context.go('/summary'),
                      child: Text('건너뛰기', style: AppTokens.buttonSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
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
                          : Text('다음', style: AppTokens.buttonPrimary),
                    ),
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
