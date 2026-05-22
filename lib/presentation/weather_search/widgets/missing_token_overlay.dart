import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/glass_card.dart';

/// 啟動時若 `CWA_API_TOKEN` 為空（未透過 `--dart-define` 注入），就在
/// 整個畫面上疊這張警示卡，引導使用者去 README 取得 token。
///
/// 卡片內含「我知道了」可關閉；關閉後僅本次運行不再顯示，重新啟動仍會
/// 再出現（因為 token 是 compile-time 常數，不裝就永遠 missing）。
class MissingTokenOverlay extends StatelessWidget {
  const MissingTokenOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withValues(alpha: 0.45),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: GestureDetector(
            // 卡片本身的點擊不要被當成 backdrop dismiss
            onTap: () {},
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentSun.withValues(alpha: 0.22),
                      border: Border.all(
                        color: AppTheme.accentSun.withValues(alpha: 0.55),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.key_off_rounded,
                      size: 40,
                      color: AppTheme.accentSun,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '需要 CWA API Token',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '尚未注入 API 授權碼',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '此 App 需要 CWA Open Data 授權碼才能取得天氣資料。\n請參考 README 的 Configuration 章節取得 token，'
                    '透過 --dart-define 注入後重新啟動。',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.55,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: onDismiss,
                        child: const Text('我知道了'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
