import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tuoi Cay'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: SupabaseService.watchState(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final state = snapshot.data!;
          final pumpOn   = state['pump_on']   ?? false;
          final valve1On = state['valve1_on'] ?? false;
          final valve2On = state['valve2_on'] ?? false;
          final autoMode = state['auto_mode'] ?? false;
          final lowWater = state['low_water'] ?? false;
          final soilPct  = state['soil_pct']  ?? 0;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Cảnh báo cạn nước
                if (lowWater)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 8),
                        Text('CẠN NƯỚC — Hệ thống đã dừng',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Độ ẩm đất
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text('Độ ẩm đất',
                          style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('$soilPct%',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        LinearProgressIndicator(
                          value: soilPct / 100,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Trạng thái
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _statusRow('Chế độ', autoMode ? 'AUTO' : 'MANUAL',
                          autoMode ? Colors.blue : Colors.grey),
                        _statusRow('Bơm',   pumpOn   ? 'BẬT' : 'TẮT',
                          pumpOn   ? Colors.green : Colors.grey),
                        _statusRow('Van 1', valve1On ? 'MỞ'  : 'ĐÓNG',
                          valve1On ? Colors.green : Colors.grey),
                        _statusRow('Van 2', valve2On ? 'MỞ'  : 'ĐÓNG',
                          valve2On ? Colors.green : Colors.grey),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Nút điều khiển
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: lowWater ? null : () =>
                      context.push('/control'),
                    icon: const Icon(Icons.tune),
                    label: const Text('Điều khiển'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}