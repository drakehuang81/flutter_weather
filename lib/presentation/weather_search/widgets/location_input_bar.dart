import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 頁面頂部的搜尋列：glass 風格 TextField + 「確認」按鈕。
///
/// 按鈕僅有 enable / disable 兩態；搜尋中由父層把 [enabled] 設為 false
/// 即可，按鈕內部不顯示 loader（loader 由結果區的骨架負責）。
class LocationInputBar extends StatefulWidget {
  const LocationInputBar({
    super.key,
    required this.onSubmit,
    this.enabled = true,
  });

  final ValueChanged<String> onSubmit;
  final bool enabled;

  @override
  State<LocationInputBar> createState() => _LocationInputBarState();
}

class _LocationInputBarState extends State<LocationInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => widget.onSubmit(_controller.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '搜尋城市',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                if (widget.enabled) _submit();
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            height: 48,
            child: FilledButton(
              onPressed: widget.enabled ? _submit : null,
              child: const Text('確認'),
            ),
          ),
        ],
      ),
    );
  }
}
