import 'package:flutter/material.dart';

import '../weather_view_state.dart';
import 'error_view.dart';
import 'forecast_view.dart';
import 'initial_view.dart';
import 'skeleton_view.dart';

/// 結果區：依 [state] 切換 4 個子 widget；以 [AnimatedSwitcher] 做 360ms
/// fade+slide 過渡。
class WeatherResultSection extends StatelessWidget {
  const WeatherResultSection({
    super.key,
    required this.state,
    this.onRetry,
  });

  final WeatherViewState state;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(_keyFor(state)),
        child: _resolve(state),
      ),
    );
  }

  Object _keyFor(WeatherViewState s) => switch (s) {
        WeatherInitial() => 'initial',
        WeatherLoading(queryingCity: final c) => 'loading:$c',
        WeatherLoaded(forecast: final f) => 'loaded:${f.city.value}',
        WeatherFailed(lastQuery: final q, title: final t) => 'failed:$t:$q',
      };

  Widget _resolve(WeatherViewState s) {
    return switch (s) {
      WeatherInitial() => const InitialView(),
      WeatherLoading() => const SkeletonView(),
      WeatherLoaded(forecast: final f) => ForecastView(forecast: f),
      WeatherFailed(title: final t, message: final m) => ErrorView(
          title: t,
          message: m,
          icon: _iconFor(s.failure.runtimeType.toString()),
          onRetry: onRetry,
        ),
    };
  }

  IconData _iconFor(String failureType) {
    if (failureType.contains('CityNotFound')) {
      return Icons.search_off_rounded;
    }
    if (failureType.contains('InvalidCityName')) {
      return Icons.edit_off_rounded;
    }
    return Icons.cloud_off_rounded;
  }
}
