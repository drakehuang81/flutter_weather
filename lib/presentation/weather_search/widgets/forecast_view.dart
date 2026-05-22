import 'package:flutter/material.dart';

import '../../../domain/weather_forecast/forecast_period.dart';
import '../../../domain/weather_forecast/weather_forecast.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_card.dart';
import '../../theme/weather_icon.dart';

/// 狀態 ③：成功取得預報資料。
///
/// - 0 筆：顯示空狀態提示
/// - 1 筆：hero 大卡 + 後續時段 list
/// - 多筆：vertical list of compact city card（瀏覽模式）
class ForecastView extends StatelessWidget {
  const ForecastView({super.key, required this.forecasts});

  final List<WeatherForecast> forecasts;

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) return const _EmptyState();
    if (forecasts.length == 1) {
      return _SingleForecastView(forecast: forecasts.first);
    }
    return _MultiForecastView(forecasts: forecasts);
  }
}

// ── 0 筆 ─────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Text(
          '目前沒有可顯示的預報',
          style: theme.textTheme.titleMedium,
        ),
      ),
    );
  }
}

// ── 1 筆：hero + period cards ────────────────────────────────

class _SingleForecastView extends StatelessWidget {
  const _SingleForecastView({required this.forecast});

  final WeatherForecast forecast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = forecast.periods.first;
    final rest = forecast.periods.skip(1).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _HeroCard(city: forecast.city.value, period: first),
        const SizedBox(height: 24),
        if (rest.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '未來時段',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...rest.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PeriodCard(period: p),
              )),
        ],
        const SizedBox(height: 8),
        Center(
          child: Text(
            '更新於 ${_formatDateTime(forecast.fetchedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 多筆：vertical compact list ──────────────────────────────

class _MultiForecastView extends StatelessWidget {
  const _MultiForecastView({required this.forecasts});

  final List<WeatherForecast> forecasts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Text(
            '全部縣市  ·  ${forecasts.length} 筆',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...forecasts.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CitySummaryCard(forecast: f),
            )),
      ],
    );
  }
}

class _CitySummaryCard extends StatelessWidget {
  const _CitySummaryCard({required this.forecast});

  final WeatherForecast forecast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = forecast.periods.first;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  forecast.city.value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  first.description,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.water_drop_outlined,
                        size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${first.precipitationProbability.value}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            weatherIconFor(first.description),
            size: 40,
            color: Colors.white.withValues(alpha: 0.92),
          ),
          const SizedBox(width: 12),
          Text(
            '${first.temperature.min}°/${first.temperature.max}°',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 共用元件（單筆畫面內部）──────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.city, required this.period});

  final String city;
  final ForecastPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avgTemp =
        ((period.temperature.min + period.temperature.max) / 2).round();

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
                  children: [
                    Text(
                      city,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRange(period.startTime, period.endTime),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                weatherIconFor(period.description),
                size: 56,
                color: AppTheme.accentSun,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$avgTemp',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 96,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '°',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  '${period.temperature.min}° / ${period.temperature.max}°',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            period.description,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatChip(
                icon: Icons.water_drop_outlined,
                label: '降雨機率',
                value: '${period.precipitationProbability.value}%',
              ),
              _StatChip(
                icon: Icons.spa_outlined,
                label: '舒適度',
                value: period.comfortIndex,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.period});

  final ForecastPeriod period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(
            weatherIconFor(period.description),
            size: 36,
            color: Colors.white.withValues(alpha: 0.92),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatRange(period.startTime, period.endTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  period.description,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.water_drop_outlined,
                        size: 14, color: AppTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${period.precipitationProbability.value}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${period.temperature.min}° / ${period.temperature.max}°',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 6),
          Text(
            '$label  ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textTertiary,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.month}/${dt.day} ${two(dt.hour)}:${two(dt.minute)}';
}

String _formatRange(DateTime a, DateTime b) {
  String two(int n) => n.toString().padLeft(2, '0');
  final sameDay = a.year == b.year && a.month == b.month && a.day == b.day;
  final aStr = '${a.month}/${a.day} ${two(a.hour)}:${two(a.minute)}';
  final bStr = sameDay
      ? '${two(b.hour)}:${two(b.minute)}'
      : '${b.month}/${b.day} ${two(b.hour)}:${two(b.minute)}';
  return '$aStr  →  $bStr';
}
