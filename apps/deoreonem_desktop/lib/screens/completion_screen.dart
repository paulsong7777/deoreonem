import 'dart:io';

import 'package:flutter/material.dart';
import '../theme.dart';

class CompletionScreen extends StatelessWidget {
  /// Injectable close action for testability. Defaults to exit(0) on desktop.
  final VoidCallback? onClose;

  const CompletionScreen({super.key, this.onClose});

  void _handleClose() {
    if (onClose != null) {
      onClose!();
    } else {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                '오늘은 여기까지\n해도 됩니다.',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 28,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                '수고하셨어요.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              TextButton(
                onPressed: _handleClose,
                child: const Text(
                  '닫기',
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
