import 'package:flutter/material.dart';
import '../models/valve_model.dart';
import '../core/theme.dart';
import '../core/constants.dart';

/// ValveCard — Widget hiển thị trạng thái 1 van tưới
class ValveCard extends StatelessWidget {
  final ValveModel valve;
  final int moisture;
  final VoidCallback onToggle;
  final bool showDetail;

  const ValveCard({
    super.key,
    required this.valve,
    required this.moisture,
    required this.onToggle,
    this.showDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(AppConstants.zoneColorValues[valve.index]);
    final isOpen = valve.isOpen;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isOpen ? color.withOpacity(0.12) : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen ? color.withOpacity(0.6) : AppTheme.bgBorder,
          width: isOpen ? 1.5 : 1,
        ),
        boxShadow: isOpen
            ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 12, spreadRadius: 0)]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          // ─── Ikon van ─────────────────────────────────
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isOpen ? color.withOpacity(0.2) : AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOpen ? Icons.water_rounded : Icons.do_not_disturb_alt_rounded,
              color: isOpen ? color : AppTheme.textDisabled,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // ─── Thông tin ────────────────────────────────
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppConstants.zoneNames[valve.index],
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(children: [
                _MoistureDot(moisture: moisture, color: color),
                const SizedBox(width: 6),
                Text('$moisture% độ ẩm',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                if (showDetail) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 1, height: 10,
                    color: AppTheme.bgBorder,
                  ),
                  const SizedBox(width: 8),
                  Text(isOpen ? 'Đang tưới' : 'Chờ',
                      style: TextStyle(fontSize: 12, color: isOpen ? color : AppTheme.textDisabled)),
                ],
              ]),
            ]),
          ),

          // ─── Toggle ───────────────────────────────────
          valve.isLoading
              ? SizedBox(width: 36, height: 36,
                  child: CircularProgressIndicator(color: color, strokeWidth: 2.5))
              : GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52, height: 28,
                    decoration: BoxDecoration(
                      color: isOpen ? color : AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isOpen ? color : AppTheme.bgBorder),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: isOpen ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 22, height: 22,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                ),
        ]),
      ),
    );
  }
}

class _MoistureDot extends StatelessWidget {
  final int moisture; final Color color;
  const _MoistureDot({required this.moisture, required this.color});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    if (moisture < 25)      dotColor = AppTheme.danger;
    else if (moisture < 50) dotColor = AppTheme.warning;
    else                    dotColor = AppTheme.primary;
    return Container(width: 8, height: 8,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle));
  }
}

extension _ThemeExt on AppTheme {
  static const Color bgSurface    = Color(0xFF1A2236);
  static const Color textDisabled = Color(0xFF4A5568);
}
