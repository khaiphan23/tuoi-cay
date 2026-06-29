import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  void _send(String cmd) => SupabaseService.sendCommand(cmd);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Điều khiển')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: SupabaseService.watchState(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final state    = snapshot.data!;
          final pumpOn   = state['pump_on']   ?? false;
          final valve1On = state['valve1_on'] ?? false;
          final valve2On = state['valve2_on'] ?? false;
          final autoMode = state['auto_mode'] ?? false;
          final lowWater = state['low_water'] ?? false;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Chế độ AUTO / MANUAL
                Row(
                  children: [
                    Expanded(
                      child: _modeBtn('MANUAL', !autoMode,
                        () => _send('MANUAL')),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _modeBtn('AUTO', autoMode,
                        () => _send('AUTO')),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Bơm
                _controlRow('Bơm', pumpOn,
                  onTap: lowWater || autoMode ? null : () =>
                    _send(pumpOn ? 'POFF' : 'PON')),

                // Van 1
                _controlRow('Van 1', valve1On,
                  onTap: lowWater || autoMode ? null : () =>
                    _send(valve1On ? 'V1OFF' : 'V1ON')),

                // Van 2
                _controlRow('Van 2', valve2On,
                  onTap: lowWater || autoMode ? null : () =>
                    _send(valve2On ? 'V2OFF' : 'V2ON')),

                const Divider(),
                const SizedBox(height: 8),

                // Nút tổng
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: lowWater || autoMode ? null
                          : () => _send('ON'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Text('BẬT TẤT CẢ',
                          style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: autoMode ? null : () => _send('OFF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: const Text('TẮT TẤT CẢ',
                          style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _modeBtn(String label, bool active, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? Colors.blue : Colors.grey.shade200,
        foregroundColor: active ? Colors.white : Colors.black,
        padding: const EdgeInsets.all(14),
      ),
      child: Text(label, style: const TextStyle(fontSize: 15)),
    );
  }

  Widget _controlRow(String label, bool isOn, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Switch(
            value: isOn,
            onChanged: onTap == null ? null : (_) => onTap(),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}