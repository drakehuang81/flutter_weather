import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 啟動畫面。
///
/// 與 [WeatherSearchPage] 共享 [AppTheme.skyGradient]，故由 `_AppRoot` 用
/// 純 fade 切換時兩屏背景連續、視覺穩定。
///
/// 內容：浮動雲朵 + 標題 + slogan + 進度線條；總顯示時間約 1.6s，跑完
/// 觸發 [onComplete]。
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onComplete,
    this.duration = const Duration(milliseconds: 1600),
  });

  final VoidCallback onComplete;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _floatCtrl;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _completeTimer = Timer(widget.duration, widget.onComplete);
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final iconAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );
    final titleAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.25, 0.9, curve: Curves.easeOut),
    );
    final progressAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.skyGradient),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Floating(
                anim: _floatCtrl,
                child: FadeTransition(
                  opacity: iconAnim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.7, end: 1).animate(iconAnim),
                    child: Icon(
                      Icons.wb_cloudy_rounded,
                      size: 132,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: titleAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(titleAnim),
                  child: Column(
                    children: [
                      Text(
                        'Flutter Weather',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Powered by CWA Open Data',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textTertiary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              FadeTransition(
                opacity: progressAnim,
                child: const _ProgressLine(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Floating extends StatelessWidget {
  const _Floating({required this.anim, required this.child});

  final Animation<double> anim;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, c) => Transform.translate(
        offset: Offset(0, -6 + anim.value * 12),
        child: c,
      ),
      child: child,
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          valueColor:
              AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.85)),
        ),
      ),
    );
  }
}
