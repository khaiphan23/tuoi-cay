import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/sensor_controller.dart';
import '../models/sensor_model.dart';
import '../core/theme.dart';
import '../core/constants.dart';

/// HistoryScreen — Biểu đồ lịch sử cảm biến 24h
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sensor = Get.find<SensorController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(children: [
            // ─── Header ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                const Expanded(child: Text('Lịch sử 24h',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => sensor.loadHistory(),
                ),
              ]),
            ),

            // ─── TabBar ──────────────────────────────────────
            TabBar(
              controller: _tabCtrl,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primary,
              dividerColor: AppTheme.bgBorder,
              tabs: const [
                Tab(text: 'Độ ẩm đất'),
                Tab(text: 'Nhiệt độ'),
                Tab(text: 'Mực nước'),
              ],
            ),

            // ─── Chart body ──────────────────────────────────
            Expanded(
              child: Obx(() {
                if (sensor.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                }
                final history = sensor.historyLast(48);
                return TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _MoistureChart(history: history),
                    _TempHumidityChart(history: history),
                    _WaterLevelChart(history: history),
                  ],
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Biểu đồ độ ẩm đất ──────────────────────────────────────
class _MoistureChart extends StatelessWidget {
  final List<SensorModel> history;
  const _MoistureChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final colors = AppConstants.zoneColorValues.map((v) => Color(v)).toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Legend
        Wrap(
          spacing: 12, runSpacing: 4,
          children: List.generate(AppConstants.numZones, (i) => Row(
            mainAxisSize: MainAxisSize.min, children: [
              Container(width: 12, height: 3, decoration: BoxDecoration(color: colors[i], borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('Khu ${i+1}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          )),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: history.isEmpty
              ? const Center(child: Text('Không có dữ liệu', style: TextStyle(color: AppTheme.textSecondary)))
              : LineChart(
                  LineChartData(
                    minY: 0, maxY: 100,
                    gridData: FlGridData(
                      drawHorizontalLine: true,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (_) =>
                          const FlLine(color: AppTheme.bgBorder, strokeWidth: 1),
                      drawVerticalLine: false,
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true, interval: 25,
                        getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      )),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true, interval: (history.length / 4).ceilToDouble(),
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= history.length) return const SizedBox.shrink();
                          return Text(
                            DateFormat('HH:mm').format(history[idx].recordedAt),
                            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                          );
                        },
                      )),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: List.generate(AppConstants.numZones, (zi) =>
                      LineChartBarData(
                        color: colors[zi],
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: colors[zi].withOpacity(0.07),
                        ),
                        spots: history.asMap().entries.map((e) =>
                          FlSpot(e.key.toDouble(), e.value.moisture[zi].toDouble())
                        ).toList(),
                      )
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

class _TempHumidityChart extends StatelessWidget {
  final List<SensorModel> history;
  const _TempHumidityChart({required this.history});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: history.isEmpty
          ? const Center(child: Text('Không có dữ liệu', style: TextStyle(color: AppTheme.textSecondary)))
          : LineChart(LineChartData(
              gridData: FlGridData(
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.bgBorder, strokeWidth: 1),
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 10,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)))),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  color: AppTheme.warning, barWidth: 2,
                  dotData: const FlDotData(show: false),
                  spots: history.asMap().entries.map((e) =>
                      FlSpot(e.key.toDouble(), e.value.airTemp)).toList(),
                ),
                LineChartBarData(
                  color: AppTheme.secondary, barWidth: 2,
                  dotData: const FlDotData(show: false),
                  spots: history.asMap().entries.map((e) =>
                      FlSpot(e.key.toDouble(), e.value.airHumidity)).toList(),
                ),
              ],
            )),
    );
  }
}

class _WaterLevelChart extends StatelessWidget {
  final List<SensorModel> history;
  const _WaterLevelChart({required this.history});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: history.isEmpty
          ? const Center(child: Text('Không có dữ liệu', style: TextStyle(color: AppTheme.textSecondary)))
          : LineChart(LineChartData(
              minY: 0, maxY: 100,
              gridData: FlGridData(
                drawHorizontalLine: true,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.bgBorder, strokeWidth: 1),
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 25,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)))),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  color: AppTheme.primary, barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: AppTheme.primary.withOpacity(0.1)),
                  spots: history.asMap().entries.map((e) =>
                      FlSpot(e.key.toDouble(), e.value.waterLevel)).toList(),
                ),
              ],
            )),
    );
  }
}
