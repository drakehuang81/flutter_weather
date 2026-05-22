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
    // 純 fade（不再 slide）— 多個 GlassCard 的 BackdropFilter 在 cross-fade
    // 期間會 sample 對方層，疊上 slide 會視覺上 jiggle。改為單純 fade，
    // 縮短 duration 後體感不會輸 slide 太多但乾淨許多。
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey(_keyFor(state)),
        child: _resolve(state),
      ),
    );
  }

  Object _keyFor(WeatherViewState s) => switch (s) {
        WeatherInitial() => 'initial',
        WeatherLoading(queryingLabel: final c) => 'loading:$c',
        WeatherLoaded(forecasts: final fs) =>
          'loaded:${fs.length}:${fs.isEmpty ? '' : fs.first.city.value}',
        WeatherFailed(lastQuery: final q, title: final t) => 'failed:$t:$q',
      };

  Widget _resolve(WeatherViewState s) {
    return switch (s) {
      WeatherInitial() => const InitialView(),
      WeatherLoading() => const SkeletonView(),
      WeatherLoaded(forecasts: final fs) => ForecastView(forecasts: fs),
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
