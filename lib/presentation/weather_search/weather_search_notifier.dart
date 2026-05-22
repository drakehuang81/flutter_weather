import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/result.dart';
import '../../composition/providers.dart';
import '../../domain/weather_forecast/failure.dart';
import 'weather_view_state.dart';

/// 搜尋頁的 Riverpod Notifier。
///
/// 每次 [search] 都呼叫 [GetCityForecast]（=> Repository.fetchForecasts =>
/// CWA API）：
///   - 輸入非空 → 查單一城市
///   - 輸入為空 → 「瀏覽模式」，回全 22 縣市
class WeatherSearchNotifier extends Notifier<WeatherViewState> {
  @override
  WeatherViewState build() => const WeatherInitial();

  /// 最短的 Loading 顯示時間。Use Case 完成更快時補齊到此值，避免畫面
  /// 一閃而過、體感像「沒在做事」；同時也吸收輸入無效時 VO 早期失敗的瞬間。
  static const _minLoadingDuration = Duration(milliseconds: 500);

  Future<void> search(String rawInput) async {
    final trimmed = rawInput.trim();
    final label = trimmed.isEmpty ? '全部縣市' : trimmed;
    state = WeatherLoading(label);
    final startedAt = DateTime.now();

    final result = await ref.read(getCityForecastProvider).call(rawInput);

    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < _minLoadingDuration) {
      await Future<void>.delayed(_minLoadingDuration - elapsed);
    }

    state = switch (result) {
      Ok(value: final forecasts) => WeatherLoaded(forecasts),
      Err(failure: final f) => WeatherFailed(
          title: _titleFor(f),
          message: _humanize(f, trimmed),
          lastQuery: trimmed,
          failure: f,
        ),
    };
  }

  /// 給 ErrorView 重試按鈕：以最近一次輸入再打一次。
  Future<void> retry() async {
    final current = state;
    if (current is WeatherFailed) {
      await search(current.lastQuery);
    }
  }

  // ── Failure → UI 文字 ─────────────────────────────────────

  String _titleFor(DomainFailure f) => switch (f) {
        InvalidCityNameError() => '輸入無效',
        CityNotFoundError() => '查無結果',
        NetworkUnavailableError() => '連線異常',
        RemoteServiceError() => '伺服器錯誤',
        MalformedForecastDataError() => '資料異常',
      };

  String _humanize(DomainFailure f, String query) => switch (f) {
        InvalidCityNameError() => '請輸入有效的城市名稱',
        CityNotFoundError(cityName: final c) => '找不到「$c」的預報資料',
        NetworkUnavailableError() => '網路連線失敗，請檢查網路設定',
        RemoteServiceError(statusCode: final s) => '伺服器錯誤（${s ?? '未知'}）',
        MalformedForecastDataError() => '伺服器回傳的資料格式不正確',
      };
}

final weatherSearchNotifierProvider =
    NotifierProvider<WeatherSearchNotifier, WeatherViewState>(
  WeatherSearchNotifier.new,
);
