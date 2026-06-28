import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/irrigation_controller.dart';
import '../controllers/sensor_controller.dart';
import '../widgets/valve_card.dart';
import '../widgets/pump_card.dart';
import '../core/theme.dart';

/// ControlScreen — Điều khiển thủ công
class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl   = Get.find<IrrigationController>();
    final sensor = Get.find<SensorController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                title: const Text('Điều khiển thủ công'),
                actions: [
                  Obx(() => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _ModeChip(
                      isAuto: ctrl.isAutoMode,
                      onToggle: () => ctrl.setMode(ctrl.isAutoMode ? 'MANUAL' : 'AUTO'),
                    ),
                  )),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ─── Bơm ──────────────────────────────────
                    const _SectionHeader(title: 'Bơm chính', icon: Icons.water_drop_rounded),
                    const SizedBox(height: 8),
                    Obx(() => PumpCard(pump: ctrl.pump.value, onToggle: ctrl.togglePump)),
                    const SizedBox(height: 24),

                    // ─── Van tưới ─────────────────────────────
                    Obx(() => _SectionHeader(
                      title: 'Van tưới — ${ctrl.openValveCount} đang mở',
                      icon: Icons.valve,
                    )),
                    const SizedBox(height: 8),

                    Obx(() => ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ctrl.valves.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => ValveCard(
                        valve: ctrl.valves[i],
                        moisture: sensor.current.value.moisture[i],
                        onToggle: () => ctrl.toggleValve(i),
                        showDetail: true,
                      ),
                    )),

                    const SizedBox(height: 24),

                    // ─── Quick Actions ───────────────────────
                    const _SectionHeader(title: 'Thao tác nhanh', icon: Icons.flash_on_rounded),
                    const SizedBox(height: 12),
                    _QuickActions(ctrl: ctrl),
                    const SizedBox(height: 30),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppTheme.primary, size: 18),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
    ]);
  }
}

class _ModeChip extends StatelessWidget {
  final bool isAuto;
  final VoidCallback onToggle;
  const _ModeChip({required this.isAuto, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isAuto ? AppTheme.primary.withOpacity(0.15) : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isAuto ? AppTheme.primary : AppTheme.bgBorder),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(isAuto ? Icons.auto_mode_rounded : Icons.pan_tool_outlined,
              size: 14, color: isAuto ? AppTheme.primary : AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(isAuto ? 'AUTO' : 'MANUAL',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isAuto ? AppTheme.primary : AppTheme.textSecondary)),
        ]),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final IrrigationController ctrl;
  const _QuickActions({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: [
        _ActionBtn(label: 'Mở tất cả van', icon: Icons.open_in_full_rounded,
            color: AppTheme.secondary,
            onTap: () async { for (int i = 0; i < 4; i++) await ctrl.toggleValve(i); }),
        _ActionBtn(label: 'Đóng tất cả van', icon: Icons.close_fullscreen_rounded,
            color: AppTheme.warning, onTap: ctrl.stopAll),
        _ActionBtn(label: 'Chỉ bật bơm', icon: Icons.water_drop_rounded,
            color: AppTheme.primary, onTap: ctrl.togglePump),
        _ActionBtn(label: 'Dừng khẩn cấp', icon: Icons.stop_rounded,
            color: AppTheme.danger, onTap: ctrl.stopAll),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }
}

// ─── Missing imports for AppTheme fields ──────────────────
extension _ThemeX on AppTheme {
  static const Color bgSurface = Color(0xFF1A2236);
}
