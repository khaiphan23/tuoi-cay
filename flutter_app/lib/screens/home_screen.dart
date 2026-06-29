import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/irrigation_controller.dart';
import '../controllers/sensor_controller.dart';
import '../widgets/valve_card.dart';
import '../widgets/pump_card.dart';
import '../widgets/soil_gauge.dart';
import '../widgets/water_status.dart';
import '../core/theme.dart';
import '../core/constants.dart';

/// HomeScreen — Tổng quan hệ thống tưới
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final irrigation = Get.find<IrrigationController>();
    final sensor     = Get.find<SensorController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async {
              await irrigation.fetchStatus();
              await sensor.fetchLatest();
            },
            child: CustomScrollView(
              slivers: [
                // ─── AppBar ──────────────────────────────────
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  title: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Smart Irrigation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Obx(() => Text(
                        irrigation.isAutoMode ? '● Chế độ TỰ ĐỘNG' : '● Chế độ THỦ CÔNG',
                        style: TextStyle(
                          fontSize: 11,
                          color: irrigation.isAutoMode ? AppTheme.primary : AppTheme.textSecondary,
                        ),
                      )),
                    ]),
                  ]),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () { irrigation.fetchStatus(); sensor.fetchLatest(); },
                    ),
                  ],
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([

                      // ─── Trạng thái mực nước ───────────────
                      Obx(() => WaterStatusWidget(
                        levelPercent: sensor.current.value.waterLevel,
                      )),
                      const SizedBox(height: 16),

                      // ─── Thông số môi trường ────────────────
                      Obx(() => _EnvironmentRow(
                        temp:     sensor.current.value.airTemp,
                        humidity: sensor.current.value.airHumidity,
                      )),
                      const SizedBox(height: 20),

                      // ─── Bơm ────────────────────────────────
                      const Text('Bơm chính', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary,
                      )),
                      const SizedBox(height: 8),
                      Obx(() => PumpCard(
                        pump:     irrigation.pump.value,
                        onToggle: irrigation.togglePump,
                      )),
                      const SizedBox(height: 20),

                      // ─── Độ ẩm đất ──────────────────────────
                      const Text('Độ ẩm đất', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary,
                      )),
                      const SizedBox(height: 8),
                      Obx(() => GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: AppConstants.numZones,
                        itemBuilder: (_, i) => SoilGauge(
                          zoneIndex: i,
                          percent: sensor.current.value.moisture[i].toDouble(),
                          label: 'Khu ${i + 1}',
                        ),
                      )),
                      const SizedBox(height: 20),

                      // ─── Van tưới ───────────────────────────
                      const Text('Van tưới', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary,
                      )),
                      const SizedBox(height: 8),
                      Obx(() => Column(
                        children: irrigation.valves.asMap().entries.map((e) =>
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ValveCard(
                              valve: e.value,
                              moisture: sensor.current.value.moisture[e.key],
                              onToggle: () => irrigation.toggleValve(e.key),
                            ),
                          )
                        ).toList(),
                      )),

                      // ─── Nút dừng khẩn cấp ──────────────────
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          id: 'btn-stop-all',
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.danger.withOpacity(0.15),
                            foregroundColor: AppTheme.danger,
                            side: const BorderSide(color: AppTheme.danger),
                          ),
                          icon: const Icon(Icons.stop_circle_rounded),
                          label: const Text('DỪNG TẤT CẢ'),
                          onPressed: () => _confirmStopAll(context, irrigation),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmStopAll(BuildContext context, IrrigationController ctrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text('Xác nhận dừng'),
        content: const Text('Tắt tất cả van và bơm ngay lập tức?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger, foregroundColor: Colors.white),
            onPressed: () { Navigator.pop(context); ctrl.stopAll(); },
            child: const Text('Dừng ngay'),
          ),
        ],
      ),
    );
  }
}

class _EnvironmentRow extends StatelessWidget {
  final double temp, humidity;
  const _EnvironmentRow({required this.temp, required this.humidity});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _EnvCard(icon: Icons.thermostat_rounded, label: 'Nhiệt độ',
          value: '${temp.toStringAsFixed(1)}°C', color: AppTheme.warning)),
      const SizedBox(width: 12),
      Expanded(child: _EnvCard(icon: Icons.water_rounded, label: 'Độ ẩm KK',
          value: '${humidity.toStringAsFixed(1)}%', color: AppTheme.secondary)),
    ]);
  }
}

class _EnvCard extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _EnvCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        ]),
      ]),
    );
  }
}
