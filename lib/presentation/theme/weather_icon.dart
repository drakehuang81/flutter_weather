import 'package:flutter/material.dart';

/// 依 CWA `Wx.parameterName` 對應到 Material 圖示。
///
/// 規則由特定 → 通用：先比對「雷雨」「雨」「雪」等明確字眼，最後 fallback
/// 為「多雲」icon，避免把「晴時多雲」誤判為純晴天。
IconData weatherIconFor(String description) {
  final d = description;
  if (d.contains('雷')) return Icons.thunderstorm_rounded;
  if (d.contains('雪')) return Icons.ac_unit_rounded;
  if (d.contains('雨')) return Icons.grain_rounded;
  if (d.contains('陰')) return Icons.cloud_rounded;
  if (d.contains('多雲')) {
    if (d.contains('晴')) return Icons.wb_cloudy_rounded;
    return Icons.cloud_outlined;
  }
  if (d.contains('晴')) return Icons.wb_sunny_rounded;
  if (d.contains('霧') || d.contains('靄')) return Icons.foggy;
  return Icons.cloud_outlined;
}
