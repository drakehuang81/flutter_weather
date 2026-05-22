import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/glass_card.dart';

/// 狀態 ④：錯誤 / 查無結果。
///
/// 兩種情境共用同一個 widget，僅參數不同：
///   - 初次 API 失敗：`title='連線異常'`、`onRetry != null`、icon=cloud_off
///   - 找不到城市：`title='查無結果'`、`onRetry = null`、icon=search_off
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.title = '查詢失敗',
    this.icon = Icons.cloud_off_rounded,
    this.onRetry,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // SingleChildScrollView 防止鍵盤未收起時內容 overflow（spec 雖未要求，
    // 但 LocationInputBar 觸發 error 的當下鍵盤常還在），與 InitialView
    // 的策略一致。
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
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
                  color: AppTheme.accentError.withValues(alpha: 0.18),
                  border: Border.all(
                    color: AppTheme.accentError.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 42,
                  color: AppTheme.accentError,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.textTertiary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('重新載入'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
