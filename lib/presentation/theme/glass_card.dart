import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 共用的 Glassmorphism 卡片容器。
///
/// 由 ClipRRect + BackdropFilter + 半透明 Container 三層組成；統一圓角、
/// 邊框、padding，UI 不再各別寫一次 BackdropFilter。
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppTheme.radiusGlass,
    this.blurSigma = 20,
    this.fillColor = AppTheme.glassFill,
    this.borderColor = AppTheme.glassBorder,
    this.borderWidth = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blurSigma;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: shape,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
