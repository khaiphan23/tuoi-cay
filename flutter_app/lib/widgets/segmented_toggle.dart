import 'package:flutter/material.dart';

/// SegmentedToggle — Bộ chọn 2 lựa chọn kiểu iOS/segmented control hiện đại
class SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color selectedColor;
  final Color backgroundColor;
  final Color unselectedTextColor;

  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.selectedColor = const Color(0xFF0091FF),
    this.backgroundColor = const Color(0xFFEDEFF3),
    this.unselectedTextColor = const Color(0xFF6B7280),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final segmentWidth = constraints.maxWidth / options.length;

        return Container(
          height: 44,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                alignment: Alignment(
                  options.length == 1
                      ? 0
                      : -1 + (2 * selectedIndex / (options.length - 1)),
                  0,
                ),
                child: Container(
                  width: segmentWidth - 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: selectedColor.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(options.length, (i) {
                  final isSelected = i == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(i),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : unselectedTextColor,
                          ),
                          child: Text(options[i]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}