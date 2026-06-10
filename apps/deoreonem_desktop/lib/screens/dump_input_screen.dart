import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/items_provider.dart';

class DumpInputScreen extends ConsumerStatefulWidget {
  const DumpInputScreen({super.key});

  @override
  ConsumerState<DumpInputScreen> createState() => _DumpInputScreenState();
}

class _DumpInputScreenState extends ConsumerState<DumpInputScreen> {
  final _controller = TextEditingController();
  bool _isAdding = false;

  Future<void> _addItem() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _isAdding = true);
    _controller.clear();
    await ref.read(itemsProvider.notifier).addItem(session.sessionId, text);
    if (mounted) setState(() => _isAdding = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(itemsProvider);
    final items = itemsState.valueOrNull ?? [];
    final hasError = itemsState.hasError;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('오늘 남은 것들',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '생각, 걱정, 할 일... 하나씩 적어보세요',
                    ),
                    onSubmitted: (_) => _addItem(),
                    enabled: !_isAdding,
                  ),
                ),
                const SizedBox(width: 8),
                _isAdding
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: '추가',
                      ),
              ],
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              Text(
                '항목 추가에 실패했어요. 다시 시도해 주세요.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(items[index].content),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: items.isNotEmpty ? () => context.go('/classify') : null,
              child: const Text('분류하기'),
            ),
          ],
        ),
      ),
    );
  }
}
