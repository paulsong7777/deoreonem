import 'dart:io';

import 'package:flutter/material.dart';
import '../design/app_tokens.dart';

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                '오늘은 여기까지\n해도 됩니다.',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: AppTokens.textPrimary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                '맡겨둔 것들은 다시 꺼내볼 수 있어요.\n이제 닫고 쉬어도 됩니다.',
                style: AppTokens.body,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              TextButton(
                onPressed: _handleClose,
                child: Text(
                  '닫기',
                  style: TextStyle(color: AppTokens.textSecondary, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
