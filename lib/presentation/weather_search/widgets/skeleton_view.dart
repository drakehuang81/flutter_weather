import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/glass_card.dart';

/// 狀態 ①：初次取資料中。
///
/// 「骨架加載」風格而非旋轉 spinner；layout 與 ForecastView 對齊
/// （hero card + section label + period cards），避免內容到位時的
/// layout 跳變。整體 opacity 1.2s 循環呼吸給予「正在載入」感。
class SkeletonView extends StatefulWidget {
  const SkeletonView({super.key});

  @override
  State<SkeletonView> createState() => _SkeletonViewState();
}

class _SkeletonViewState extends State<SkeletonView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _HeroSkeleton(),
          const SizedBox(height: 24),
          _LabelSkeleton(),
          const SizedBox(height: 12),
          _PeriodSkeleton(),
          const SizedBox(height: 12),
          _PeriodSkeleton(),
        ],
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Bar(width: 140, height: 22),
                    SizedBox(height: 8),
                    _Bar(width: 100, height: 12),
                  ],
                ),
              ),
              _Circle(size: 56),
            ],
          ),
          const SizedBox(height: 20),
          const _Bar(width: 180, height: 64),
          const SizedBox(height: 12),
          const _Bar(width: 120, height: 18),
          const SizedBox(height: 16),
          Row(
            children: const [
              _Bar(width: 120, height: 28, radius: 999),
              SizedBox(width: 8),
              _Bar(width: 110, height: 28, radius: 999),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabelSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: _Bar(width: 80, height: 14),
    );
  }
}

class _PeriodSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _Circle(size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Bar(width: 110, height: 10),
                SizedBox(height: 6),
                _Bar(width: 80, height: 16),
                SizedBox(height: 4),
                _Bar(width: 56, height: 10),
              ],
            ),
          ),
          const _Bar(width: 64, height: 16),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.width, required this.height, this.radius = 8});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.glassFill,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.glassBorder),
      ),
    );
  }
}
