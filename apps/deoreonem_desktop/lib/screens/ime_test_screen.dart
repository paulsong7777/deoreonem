import 'package:flutter/material.dart';

/// Temporary IME test harness for diagnosing Korean composition issues.
/// Access via /ime-test route (debug only).
/// Tests multiple TextField variants to identify which is stable.
class ImeTestScreen extends StatefulWidget {
  const ImeTestScreen({super.key});

  @override
  State<ImeTestScreen> createState() => _ImeTestScreenState();
}

class _ImeTestScreenState extends State<ImeTestScreen> {
  late final TextEditingController _controllerA;
  late final FocusNode _focusA;
  late final TextEditingController _controllerB;
  late final FocusNode _focusB;

  @override
  void initState() {
    super.initState();
    _controllerA = TextEditingController();
    _focusA = FocusNode();
    _controllerB = TextEditingController();
    _focusB = FocusNode();
  }

  @override
  void dispose() {
    _controllerA.dispose();
    _focusA.dispose();
    _controllerB.dispose();
    _focusB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Korean IME Test Harness',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Test: 걱정일뿐이야 괜찮아요 앉아있어요 읽어요 값이 비싸요',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            // Variant A: Bare minimum multiline, no decoration
            const Text('Variant A — Bare TextField (no decoration)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            SizedBox(
              height: 120,
              child: TextField(
                controller: _controllerA,
                focusNode: _focusA,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                enableIMEPersonalizedLearning: false,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Variant B: Fixed height, no expands
            const Text('Variant B — Fixed height, no expands',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            SizedBox(
              height: 120,
              child: TextField(
                controller: _controllerB,
                focusNode: _focusB,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textAlignVertical: TextAlignVertical.top,
                enableIMEPersonalizedLearning: false,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Variant C: Using Expanded but no other params
            const Text('Variant C — Expanded + expands (current DumpInput pattern)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Expanded(
              child: TextField(
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                enableIMEPersonalizedLearning: false,
                enableSuggestions: false,
                autocorrect: false,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
