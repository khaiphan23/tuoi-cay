import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';

/// AutoThresholdSlider — Cấu hình ngưỡng AUTO cho 1 khu
class AutoThresholdSlider extends StatelessWidget {
  final int zoneIndex;
  final String zoneName;
  final double lowThresh;
  final double highThresh;
  final bool enabled;
  final double currentMoisture;
  final ValueChanged<double> onLowChanged;
  final ValueChanged<double> onHighChanged;
  final VoidCallback onToggle;

  const AutoThresholdSlider({
    super.key,
    required this.zoneIndex,
    required this.zoneName,
    required this.lowThresh,
    required this.highThresh,
    required this.enabled,
    required this.currentMoisture,
    required this.onLowChanged,
    required this.onHighChanged,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final zoneColor = Color(AppConstants.zoneColorValues[zoneIndex]);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: enabled ? 1.0 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? zoneColor.withOpacity(0.4) : AppTheme.bgBorder,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ─── Header ─────────────────────────────────
            Row(children: [
              Container(width: 4, height: 40,
                  decoration: BoxDecoration(
                      color: zoneColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(zoneName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                Text('Hiện tại: ${currentMoisture.toInt()}%',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              ])),
              // Enable toggle
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, height: 24,
                  decoration: BoxDecoration(
                    color: enabled ? zoneColor : AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 20, height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // ─── Ngưỡng thấp ───────────────────────────
            _ThresholdRow(
              label: 'Ngưỡng thấp (tưới)',
              value: lowThresh,
              color: AppTheme.danger,
              icon: Icons.arrow_downward_rounded,
              onChanged: enabled
                  ? (v) { if (v < highThresh - 5) onLowChanged(v); }
                  : null,
            ),
            const SizedBox(height: 8),

            // ─── Ngưỡng cao ────────────────────────────
            _ThresholdRow(
              label: 'Ngưỡng cao (dừng)',
              value: highThresh,
              color: AppTheme.primary,
              icon: Icons.arrow_upward_rounded,
              onChanged: enabled
                  ? (v) { if (v > lowThresh + 5) onHighChanged(v); }
                  : null,
            ),
            const SizedBox(height: 10),

            // ─── Thanh trực quan ────────────────────────
            _RangeVisual(
              low: lowThresh, high: highThresh,
              current: currentMoisture, color: zoneColor,
            ),
          ]),
        ),
      ),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  final String label; final double value; final Color color;
  final IconData icon; final ValueChanged<double>? onChanged;
  const _ThresholdRow({required this.label, required this.value, required this.color,
      required this.icon, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const Spacer(),
        Text('${value.toInt()}%',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ]),
      SliderTheme(
        data: SliderThemeData(
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          activeTrackColor: color,
          inactiveTrackColor: AppTheme.bgBorder,
          thumbColor: color,
          overlayColor: color.withOpacity(0.15),
        ),
        child: Slider(
          value: value,
          min: 0, max: 100,
          divisions: 20,
          onChanged: onChanged,
        ),
      ),
    ]);
  }
}

class _RangeVisual extends StatelessWidget {
  final double low, high, current; final Color color;
  const _RangeVisual({required this.low, required this.high, required this.current, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      final lowX    = (low    / 100 * w).clamp(0.0, w);
      final highX   = (high   / 100 * w).clamp(0.0, w);
      final currX   = (current/ 100 * w).clamp(0.0, w);

      return SizedBox(height: 24, child: Stack(children: [
        // Track
        Positioned(left: 0, right: 0, top: 10, child: Container(height: 4,
            decoration: BoxDecoration(color: AppTheme.bgBorder, borderRadius: BorderRadius.circular(2)))),
        // Range fill
        Positioned(left: lowX, width: (highX - lowX).clamp(0.0, w), top: 10, child:
            Container(height: 4, color: color.withOpacity(0.4))),
        // Current indicator
        Positioned(left: currX - 6, top: 4, child: Container(width: 12, height: 16,
            decoration: BoxDecoration(color: AppTheme.warning, borderRadius: BorderRadius.circular(3)),
            child: const Center(child: Text('▲', style: TextStyle(fontSize: 8, color: Colors.white))))),
      ]));
    });
  }
}

extension _ThemeExt on AppTheme {
  static const Color bgSurface = Color(0xFF1A2236);
}
