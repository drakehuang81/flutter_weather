import '../../domain/weather_forecast/failure.dart';
import '../../domain/weather_forecast/weather_forecast.dart';

/// WeatherSearch 頁面的展示狀態。
///
/// 四個密封子型別與 4 個 widget 一對一對應：
///   - [WeatherInitial] → InitialView    （未搜尋）
///   - [WeatherLoading] → SkeletonView   （搜尋中，骨架）
///   - [WeatherLoaded]  → ForecastView   （取得資料；可能 1 筆或多筆）
///   - [WeatherFailed]  → ErrorView      （錯誤 + 可重試上一筆查詢）
sealed class WeatherViewState {
  const WeatherViewState();
}

class WeatherInitial extends WeatherViewState {
  const WeatherInitial();
}

class WeatherLoading extends WeatherViewState {
  const WeatherLoading(this.queryingLabel);

  /// 顯示用的查詢標籤；指定城市時為城市名，瀏覽模式時為「全部縣市」。
  final String queryingLabel;
}

/// 載入完成。可能為單筆（指定城市）或多筆（瀏覽模式）。
class WeatherLoaded extends WeatherViewState {
  const WeatherLoaded(this.forecasts);

  final List<WeatherForecast> forecasts;
}

class WeatherFailed extends WeatherViewState {
  const WeatherFailed({
    required this.title,
    required this.message,
    required this.lastQuery,
    required this.failure,
  });

  final String title;
  final String message;

  /// 最近一次的搜尋字串（可能為空字串 = 瀏覽模式）；ErrorView 的「重試」
  /// 會用它重新發出 search。
  final String lastQuery;
  final DomainFailure failure;
}
