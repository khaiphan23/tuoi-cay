import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../widgets/ios_toggle_switch.dart';
import '../widgets/segmented_toggle.dart';
import '../widgets/modern_action_button.dart';
import '../core/theme.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  void _send(String cmd) => SupabaseService.sendCommand(cmd);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Điều khiển', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.bgGradient),
        child: StreamBuilder<Map<String, dynamic>>(
          stream: SupabaseService.watchState(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator(color: AppTheme.secondary));
            }

            final state    = snapshot.data!;
            final pumpOn   = state['pump_on']   ?? false;
            final valve1On = state['valve1_on'] ?? false;
            final valve2On = state['valve2_on'] ?? false;
            final autoMode = state['auto_mode'] ?? false;
            final lowWater = state['low_water'] ?? false;

            final locked = lowWater || autoMode;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chế độ vận hành',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary, letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SegmentedToggle(
                    options: const ['MANUAL', 'AUTO'],
                    selectedIndex: autoMode ? 1 : 0,
                    onChanged: (i) => _send(i == 1 ? 'AUTO' : 'MANUAL'),
                    selectedColor: AppTheme.secondary,
                    backgroundColor: AppTheme.bgSurface,
                    unselectedTextColor: AppTheme.textSecondary,
                  ),

                  const SizedBox(height: 28),

                  if (lowWater) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.danger.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Cạn nước — Các thiết bị đã bị khoá',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.danger),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text(
                    'Thiết bị',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.bgBorder),
                    ),
                    child: Column(
                      children: [
                        _controlRow(
                          icon: Icons.water_drop_rounded,
                          iconColor: AppTheme.secondary,
                          label: 'Bơm',
                          isOn: pumpOn,
                          onTap: locked ? null : () => _send(pumpOn ? 'POFF' : 'PON'),
                        ),
                        Divider(height: 1, indent: 60, color: AppTheme.bgBorder),
                        _controlRow(
                          icon: Icons.opacity_rounded,
                          iconColor: AppTheme.primaryDark,
                          label: 'Van 1',
                          isOn: valve1On,
                          onTap: locked ? null : () => _send(valve1On ? 'V1OFF' : 'V1ON'),
                        ),
                        Divider(height: 1, indent: 60, color: AppTheme.bgBorder),
                        _controlRow(
                          icon: Icons.opacity_rounded,
                          iconColor: AppTheme.accent,
                          label: 'Van 2',
                          isOn: valve2On,
                          onTap: locked ? null : () => _send(valve2On ? 'V2OFF' : 'V2ON'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Điều khiển tổng',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: ModernActionButton(
                          label: 'BẬT TẤT CẢ',
                          icon: Icons.power_settings_new_rounded,
                          color: AppTheme.primaryDark,
                          onTap: locked ? null : () => _send('ON'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ModernActionButton(
                          label: 'TẮT TẤT CẢ',
                          icon: Icons.stop_circle_rounded,
                          color: AppTheme.danger,
                          onTap: autoMode ? null : () => _send('OFF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _controlRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool isOn,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isOn ? iconColor.withOpacity(0.14) : AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: isOn ? iconColor : AppTheme.textDisabled),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ),
          IosToggleSwitch(
            value: isOn,
            onChanged: onTap == null ? null : (_) => onTap(),
          ),
        ],
      ),
    );
  }
}