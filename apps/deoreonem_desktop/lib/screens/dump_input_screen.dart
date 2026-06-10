import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DumpInputScreen extends StatefulWidget {
  const DumpInputScreen({super.key});

  @override
  State<DumpInputScreen> createState() => _DumpInputScreenState();
}

class _DumpInputScreenState extends State<DumpInputScreen> {
  final _controller = TextEditingController();
  final List<String> _items = [];

  void _addItem() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _items.add(text);
      _controller.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: '추가',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(_items[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removeItem(index),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _items.isNotEmpty ? () => context.go('/classify') : null,
              child: const Text('분류하기'),
            ),
          ],
        ),
      ),
    );
  }
}
