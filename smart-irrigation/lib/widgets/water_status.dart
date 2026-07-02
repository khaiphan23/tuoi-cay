import 'package:flutter/material.dart';
import '../core/theme.dart';

/// WaterStatusWidget — Hiển thị mực nước bể chứa dạng thanh ngang
class WaterStatusWidget extends StatelessWidget {
  final double levelPercent;   // 0–100

  const WaterStatusWidget({super.key, required this.levelPercent});

  Color get _barColor {
    if (levelPercent <= 10) return AppTheme.danger;
    if (levelPercent <= 20) return AppTheme.warning;
    return AppTheme.secondary;
  }

  String get _statusText {
    if (levelPercent <= 10) return '⚠ Nguy hiểm — Khóa bơm';
    if (levelPercent <= 20) return '⚠ Mực nước thấp';
    if (levelPercent <= 50) return 'Mức trung bình';
    return 'Mức tốt';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (levelPercent / 100).clamp(0.0, 1.0);
    final isCritical = levelPercent <= 10;
    final isLow      = levelPercent <= 20;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCritical
            ? AppTheme.danger.withOpacity(0.1)
            : isLow
                ? AppTheme.warning.withOpacity(0.08)
                : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical
              ? AppTheme.danger.withOpacity(0.5)
              : isLow
                  ? AppTheme.warning.withOpacity(0.4)
                  : AppTheme.bgBorder,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Icon(Icons.water, color: _barColor, size: 20),
          const SizedBox(width: 8),
          const Text('Bể nước', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${levelPercent.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _barColor)),
        ]),
        const SizedBox(height: 10),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (_, value, __) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: AppTheme.bgBorder,
                valueColor: AlwaysStoppedAnimation<Color>(_barColor),
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // Status text
        Text(_statusText,
            style: TextStyle(fontSize: 11, color: _barColor, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
