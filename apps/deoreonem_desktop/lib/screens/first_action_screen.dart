import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class FirstActionScreen extends StatefulWidget {
  const FirstActionScreen({super.key});

  @override
  State<FirstActionScreen> createState() => _FirstActionScreenState();
}

class _FirstActionScreenState extends State<FirstActionScreen> {
  // Mock eligible items (NOW/TOMORROW/THIS_WEEK only)
  final List<String> _eligibleItems = [
    'API 설계 마저 하기',
    '리뷰 요청 답변 보내기',
  ];
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('첫 번째 할 일',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              '내일 가장 먼저 할 일 하나를 고르세요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _eligibleItems.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndex == index;
                  return Card(
                    color: isSelected
                        ? AppTheme.accent.withValues(alpha: 0.1)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? AppTheme.accent : AppTheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(_eligibleItems[index]),
                      leading: Radio<int>(
                        value: index,
                        groupValue: _selectedIndex,
                        onChanged: (val) =>
                            setState(() => _selectedIndex = val),
                        activeColor: AppTheme.accent,
                      ),
                      onTap: () => setState(() => _selectedIndex = index),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/summary'),
                    child: const Text('건너뛰기'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedIndex != null
                        ? () => context.go('/summary')
                        : null,
                    child: const Text('다음'),
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
