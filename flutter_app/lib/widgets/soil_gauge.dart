import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../core/theme.dart';
import '../core/constants.dart';

/// SoilGauge — Đồng hồ đo độ ẩm đất hình tròn
class SoilGauge extends StatelessWidget {
  final int zoneIndex;
  final double percent;   // 0–100
  final String label;

  const SoilGauge({
    super.key,
    required this.zoneIndex,
    required this.percent,
    required this.label,
  });

  Color get _arcColor {
    if (percent < 25) return AppTheme.danger;
    if (percent < 50) return AppTheme.warning;
    if (percent < 75) return AppTheme.primary;
    return AppTheme.secondary;
  }

  String get _statusText {
    if (percent < 25) return 'Khô';
    if (percent < 50) return 'Hơi khô';
    if (percent < 75) return 'Tốt';
    return 'Ẩm';
  }

  @override
  Widget build(BuildContext context) {
    final zoneColor = Color(AppConstants.zoneColorValues[zoneIndex]);
    final pct = (percent / 100).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bgBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircularPercentIndicator(
            radius: 42,
            lineWidth: 7,
            percent: pct,
            animation: true,
            animationDuration: 800,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: _arcColor,
            backgroundColor: AppTheme.bgBorder,
            center: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${percent.toInt()}%',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _arcColor)),
            ]),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: zoneColor)),
          Text(_statusText,
              style: TextStyle(fontSize: 10, color: _arcColor)),
        ]),
      ),
    );
  }
}
