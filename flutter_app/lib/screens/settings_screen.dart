import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/constants.dart';

/// SettingsScreen — Cài đặt ứng dụng
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _deviceIdCtrl = TextEditingController(text: AppConstants.defaultDeviceId);
  bool _notifyWaterLow     = true;
  bool _notifyPumpTimeout  = true;
  bool _darkMode           = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifyWaterLow    = prefs.getBool('notify_water_low')    ?? true;
      _notifyPumpTimeout = prefs.getBool('notify_pump_timeout') ?? true;
      _deviceIdCtrl.text = prefs.getString('device_id') ?? AppConstants.defaultDeviceId;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_water_low',    _notifyWaterLow);
    await prefs.setBool('notify_pump_timeout', _notifyPumpTimeout);
    await prefs.setString('device_id', _deviceIdCtrl.text.trim());
    Get.snackbar('Đã lưu', 'Cài đặt đã được cập nhật',
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.transparent,
                title: const Text('Cài đặt'),
                actions: [
                  TextButton(
                    onPressed: _savePrefs,
                    child: const Text('Lưu', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // ─── Thiết bị ───────────────────────────
                    _SettingsSection(
                      title: 'Thiết bị',
                      children: [
                        _SettingsTextField(
                          label: 'Device ID',
                          controller: _deviceIdCtrl,
                          hint: 'esp32-node-01',
                          icon: Icons.developer_board_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── Thông báo ──────────────────────────
                    _SettingsSection(
                      title: 'Thông báo',
                      children: [
                        _SettingsSwitch(
                          label: 'Cảnh báo mực nước thấp',
                          subtitle: 'Thông báo khi bể < 20%',
                          value: _notifyWaterLow,
                          icon: Icons.water_drop_outlined,
                          onChanged: (v) => setState(() => _notifyWaterLow = v),
                        ),
                        _SettingsSwitch(
                          label: 'Cảnh báo bơm quá thời gian',
                          subtitle: 'Bơm chạy > 30 phút',
                          value: _notifyPumpTimeout,
                          icon: Icons.timer_off_rounded,
                          onChanged: (v) => setState(() => _notifyPumpTimeout = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── Thông tin ──────────────────────────
                    _SettingsSection(
                      title: 'Thông tin',
                      children: [
                        _InfoTile(label: 'Phiên bản ứng dụng', value: '1.0.0'),
                        _InfoTile(label: 'Supabase URL', value: _shortUrl(AppConstants.supabaseUrl)),
                        _InfoTile(label: 'Số van', value: '${AppConstants.numValves}'),
                        _InfoTile(label: 'Ngưỡng AUTO mặc định', value: '${AppConstants.autoMoistureLow.toInt()}% – ${AppConstants.autoMoistureHigh.toInt()}%'),
                      ],
                    ),
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

  String _shortUrl(String url) {
    try { return Uri.parse(url).host; } catch (_) { return url; }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.bgBorder),
        ),
        child: Column(children: children),
      ),
    ]);
  }
}

class _SettingsSwitch extends StatelessWidget {
  final String label, subtitle; final bool value; final IconData icon;
  final ValueChanged<bool> onChanged;
  const _SettingsSwitch({required this.label, required this.subtitle,
      required this.value, required this.icon, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      trailing: Switch(
        value: value, onChanged: onChanged,
        activeColor: AppTheme.primary,
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}

class _SettingsTextField extends StatelessWidget {
  final String label, hint; final TextEditingController controller; final IconData icon;
  const _SettingsTextField({required this.label, required this.hint,
      required this.controller, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          isDense: true,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      trailing: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
    );
  }
}
