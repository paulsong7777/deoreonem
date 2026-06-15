import 'package:flutter/material.dart';
import 'app_tokens.dart';

class ProductSurface extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;

  const ProductSurface({super.key, required this.child, this.width, this.height, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding ?? AppTokens.cardPadding,
      decoration: BoxDecoration(
        color: AppTokens.surfaceWarm,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: AppTokens.borderWarm, width: 0.5),
      ),
      child: child,
    );
  }
}

class CalmSnackBar {
  static SnackBar show(String text) {
    return SnackBar(
      content: Text(text, style: const TextStyle(fontSize: 13, color: Colors.white)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF5A5550),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final VoidCallback onNewSession;
  final bool isLoading;
  final VoidCallback onClose;

  const EmptyStateView({super.key, required this.onNewSession, required this.isLoading, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text('지금 다시 꺼내볼 것은 없습니다.', style: AppTokens.titleScreen, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('맡겨둔 것들은 모두 조용히 정리되었어요.', style: AppTokens.body, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('내려놓은 걱정은 조용한 나무의 양분이 되었어요.', style: AppTokens.body, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text('필요하면 새로 비워내고, 아니면 이대로 닫아도 괜찮습니다.', style: AppTokens.body, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Text('조용한 나무가 오늘도 자라고 있어요.', style: AppTokens.caption, textAlign: TextAlign.center),
            const Spacer(),
            SizedBox(width: 240, height: 48,
              child: ElevatedButton(onPressed: isLoading ? null : onNewSession, child: const Text('새로 비우기'))),
            const SizedBox(height: 10),
            TextButton(onPressed: onClose, child: Text('창 닫기', style: TextStyle(color: AppTokens.textSecondary, fontSize: 13))),
          ],
        ),
      ),
    );
  }
}
