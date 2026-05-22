import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 狀態 ①：尚未發起搜尋。柔和的浮動雲朵 + 引導文字。
class InitialView extends StatefulWidget {
  const InitialView({super.key});

  @override
  State<InitialView> createState() => _InitialViewState();
}

class _InitialViewState extends State<InitialView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -6 + _ctrl.value * 12),
                child: child,
              ),
              child: Icon(
                Icons.cloud_outlined,
                size: 120,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '查詢天氣預報',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              '輸入想查詢的城市名稱\n例如「臺北市」、「高雄市」',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
