import 'package:flutter/material.dart';
import '../models/pump_model.dart';
import '../core/theme.dart';

/// PumpCard — Widget hiển thị trạng thái bơm chính
class PumpCard extends StatelessWidget {
  final PumpModel pump;
  final VoidCallback onToggle;

  const PumpCard({super.key, required this.pump, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isOn = pump.isOn;
    final dur  = pump.runningDuration;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: isOn
            ? const LinearGradient(
                colors: [Color(0xFF00E5A020), Color(0xFF0091FF20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isOn ? null : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOn ? AppTheme.primary.withOpacity(0.5) : AppTheme.bgBorder,
          width: isOn ? 1.5 : 1,
        ),
        boxShadow: isOn
            ? [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 20, spreadRadius: 0)]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          // ─── Animated pump icon ────────────────────────
          _PumpIcon(isOn: isOn),
          const SizedBox(width: 16),

          // ─── Info ───────────────────────────────────────
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Bơm chính', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                _StatusBadge(isOn: isOn),
              ]),
              const SizedBox(height: 4),
              Text(
                dur != null
                    ? 'Đã chạy ${_formatDuration(dur)}'
                    : 'Nhấn để bật bơm',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ]),
          ),

          // ─── Toggle button ──────────────────────────────
          pump.isLoading
              ? const SizedBox(width: 42, height: 42,
                  child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5))
              : GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOn ? AppTheme.primary : AppTheme.bgSurface,
                      boxShadow: isOn
                          ? [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 16)]
                          : [],
                    ),
                    child: Icon(
                      isOn ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: isOn ? const Color(0xFF001A0F) : AppTheme.textSecondary,
                      size: 28,
                    ),
                  ),
                ),
        ]),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _PumpIcon extends StatefulWidget {
  final bool isOn;
  const _PumpIcon({required this.isOn});
  @override
  State<_PumpIcon> createState() => _PumpIconState();
}

class _PumpIconState extends State<_PumpIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _rotation = Tween(begin: 0.0, end: 1.0).animate(_ctrl);
    if (widget.isOn) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(_PumpIcon old) {
    super.didUpdateWidget(old);
    if (widget.isOn && !_ctrl.isAnimating) _ctrl.repeat();
    if (!widget.isOn && _ctrl.isAnimating) _ctrl.stop();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: widget.isOn ? AppTheme.primary.withOpacity(0.15) : AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _rotation,
          builder: (_, child) => Transform.rotate(
            angle: _rotation.value * 2 * 3.14159,
            child: child,
          ),
          child: Icon(Icons.settings_rounded,
              color: widget.isOn ? AppTheme.primary : AppTheme.textSecondary, size: 30),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOn;
  const _StatusBadge({required this.isOn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOn ? AppTheme.primary.withOpacity(0.15) : AppTheme.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOn ? '● BẬT' : '○ TẮT',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: isOn ? AppTheme.primary : AppTheme.danger),
      ),
    );
  }
}

extension _ThemeExt on AppTheme {
  static const Color bgSurface = Color(0xFF1A2236);
}
