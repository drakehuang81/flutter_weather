import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import 'weather_search_notifier.dart';
import 'weather_view_state.dart';
import 'widgets/location_input_bar.dart';
import 'widgets/weather_result_section.dart';

/// 天氣搜尋頁。
///
/// 全屏天空漸層做背景；AppBar 透明、頂部 [LocationInputBar]、
/// 下方 [WeatherResultSection] 鋪滿剩餘空間。
///
/// 搜尋中（[WeatherLoading]）整個輸入列 disable，避免重複觸發。
class WeatherSearchPage extends ConsumerWidget {
  const WeatherSearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(weatherSearchNotifierProvider);
    final notifier = ref.read(weatherSearchNotifierProvider.notifier);
    final inputEnabled = state is! WeatherLoading;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.skyGradient),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Flutter Weather'),
        ),
        body: SafeArea(
          child: Column(
            children: [
              LocationInputBar(
                enabled: inputEnabled,
                onSubmit: notifier.search,
              ),
              Expanded(
                child: WeatherResultSection(
                  state: state,
                  onRetry: notifier.retry,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
