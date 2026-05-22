import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/splash/splash_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/weather_search/weather_search_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light, // Android
      statusBarBrightness: Brightness.dark, // iOS
    ),
  );
  runApp(const ProviderScope(child: FlutterWeatherApp()));
}

class FlutterWeatherApp extends StatelessWidget {
  const FlutterWeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Weather',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const _AppRoot(),
    );
  }
}

/// 啟動 → SplashScreen，splash 結束後純 fade 切到 [WeatherSearchPage]。
///
/// 兩屏共用同一份 `AppTheme.skyGradient`，所以 fade 期間背景不會跳色。
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 480),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _showSplash
          ? SplashScreen(
              key: const ValueKey('splash'),
              onComplete: () => setState(() => _showSplash = false),
            )
          : const WeatherSearchPage(key: ValueKey('home')),
    );
  }
}
