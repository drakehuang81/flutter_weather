import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../composition/providers.dart';
import '../theme/app_theme.dart';
import 'weather_search_notifier.dart';
import 'weather_view_state.dart';
import 'widgets/location_input_bar.dart';
import 'widgets/missing_token_overlay.dart';
import 'widgets/weather_result_section.dart';

/// 天氣搜尋頁。
///
/// 全屏天空漸層做背景；AppBar 透明、頂部 [LocationInputBar]、
/// 下方 [WeatherResultSection] 鋪滿剩餘空間。
///
/// 若 [cwaApiTokenProvider] 為空（未注入 `--dart-define=CWA_API_TOKEN=...`），
/// 啟動時在整個畫面上疊一張 [MissingTokenOverlay] 提示。
class WeatherSearchPage extends ConsumerStatefulWidget {
  const WeatherSearchPage({super.key});

  @override
  ConsumerState<WeatherSearchPage> createState() => _WeatherSearchPageState();
}

class _WeatherSearchPageState extends ConsumerState<WeatherSearchPage> {
  bool _missingTokenDismissed = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weatherSearchNotifierProvider);
    final notifier = ref.read(weatherSearchNotifierProvider.notifier);
    final inputEnabled = state is! WeatherLoading;
    final tokenMissing = ref.watch(cwaApiTokenProvider).isEmpty;
    final showMissingToken = tokenMissing && !_missingTokenDismissed;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.skyGradient),
      child: Stack(
        children: [
          Scaffold(
            extendBodyBehindAppBar: true,
            backgroundColor: Colors.transparent,
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: showMissingToken
                ? MissingTokenOverlay(
                    key: const ValueKey('missing-token'),
                    onDismiss: () =>
                        setState(() => _missingTokenDismissed = true),
                  )
                : const SizedBox.shrink(key: ValueKey('no-overlay')),
          ),
        ],
      ),
    );
  }
}
