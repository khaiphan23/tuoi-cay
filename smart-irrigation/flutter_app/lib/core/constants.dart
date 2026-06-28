/// AppConstants — Hằng số toàn cục ứng dụng
/// ⚠️  Không commit thông tin nhạy cảm lên git
///     Dùng --dart-define hoặc .env cho production

class AppConstants {
  AppConstants._();

  // ─── Supabase ───────────────────────────────────────────
  // Thay bằng project thực tế:
  static const String supabaseUrl     = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  // ─── Device ────────────────────────────────────────────
  static const String defaultDeviceId = 'esp32-node-01';
  static const int    numValves       = 4;
  static const int    numZones        = 4;

  // ─── Polling / Realtime ─────────────────────────────────
  static const Duration sensorRefresh   = Duration(seconds: 10);
  static const Duration commandTimeout  = Duration(seconds: 30);

  // ─── Bảng Supabase ─────────────────────────────────────
  static const String tableSensorLogs  = 'sensor_logs';
  static const String tableCommands    = 'commands';
  static const String tableValveStatus = 'valve_status';
  static const String tableAutoConfig  = 'auto_config';
  static const String tableSchedules   = 'schedules';

  // ─── Thông số AUTO default ─────────────────────────────
  static const double autoMoistureLow  = 30.0;
  static const double autoMoistureHigh = 70.0;

  // ─── Tên khu ───────────────────────────────────────────
  static const List<String> zoneNames = [
    'Khu 1 — Rau xanh',
    'Khu 2 — Hoa màu',
    'Khu 3 — Cây ăn quả',
    'Khu 4 — Bãi cỏ',
  ];

  // ─── Màu khu (index-based) ─────────────────────────────
  static const List<int> zoneColorValues = [
    0xFF4CAF50,  // Xanh lá
    0xFF2196F3,  // Xanh dương
    0xFFFF9800,  // Cam
    0xFF9C27B0,  // Tím
  ];
}
