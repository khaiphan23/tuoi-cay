import 'package:flutter/material.dart';

/// IosToggleSwitch — Công tắc bật/tắt kiểu iOS hiện đại
/// OFF: nền xám, nút tròn bên trái
/// ON: nền xanh lá, nút tròn bên phải
class IosToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;
  final double height;

  const IosToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 52,
    this.height = 32,
  });

  @override
  Widget build(BuildContext context) {
    final thumbSize = height - 6;
    final enabled = onChanged != null;

    return GestureDetector(
      onTap: enabled ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        width: width,
        height: height,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: !enabled
              ? (value
                  ? const Color(0xFF34C759).withOpacity(0.35)
                  : const Color(0xFFB0B4BA).withOpacity(0.35))
              : (value ? const Color(0xFF34C759) : const Color(0xFFB8BEC9)),
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: value && enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF34C759).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}