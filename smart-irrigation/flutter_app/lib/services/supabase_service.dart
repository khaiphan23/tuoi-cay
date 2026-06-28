import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

/// SupabaseService — Wrapper cho tất cả thao tác với Supabase
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── Sensor Logs ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getSensorHistory({
    String deviceId = AppConstants.defaultDeviceId,
    int hours = 24,
  }) async {
    final since = DateTime.now().subtract(Duration(hours: hours)).toIso8601String();
    return await _client
        .from(AppConstants.tableSensorLogs)
        .select()
        .eq('device_id', deviceId)
        .gte('recorded_at', since)
        .order('recorded_at', ascending: false)
        .limit(500);
  }

  Stream<List<Map<String, dynamic>>> sensorStream({
    String deviceId = AppConstants.defaultDeviceId,
  }) {
    return _client
        .from(AppConstants.tableSensorLogs)
        .stream(primaryKey: ['id'])
        .eq('device_id', deviceId)
        .order('recorded_at', ascending: false)
        .limit(1);
  }

  // ─── Valve Status ─────────────────────────────────────────
  Future<Map<String, dynamic>?> getValveStatus({
    String deviceId = AppConstants.defaultDeviceId,
  }) async {
    final data = await _client
        .from(AppConstants.tableValveStatus)
        .select()
        .eq('device_id', deviceId)
        .maybeSingle();
    return data;
  }

  Stream<Map<String, dynamic>?> valveStatusStream({
    String deviceId = AppConstants.defaultDeviceId,
  }) {
    return _client
        .from(AppConstants.tableValveStatus)
        .stream(primaryKey: ['device_id'])
        .eq('device_id', deviceId)
        .map((rows) => rows.isNotEmpty ? rows.first : null);
  }

  // ─── Commands ─────────────────────────────────────────────
  Future<void> sendCommand({
    required String cmd,
    Map<String, dynamic> payload = const {},
    String deviceId = AppConstants.defaultDeviceId,
  }) async {
    await _client.from(AppConstants.tableCommands).insert({
      'device_id': deviceId,
      'cmd': cmd,
      'payload': payload,
      'status': 'pending',
    });
  }

  Future<void> openValve(int valveIndex) => sendCommand(
        cmd: 'open_valve',
        payload: {'valve': valveIndex + 1},
      );

  Future<void> closeValve(int valveIndex) => sendCommand(
        cmd: 'close_valve',
        payload: {'valve': valveIndex + 1},
      );

  Future<void> setPump(bool on) => sendCommand(
        cmd: 'pump',
        payload: {'state': on},
      );

  Future<void> stopAll() => sendCommand(cmd: 'stop_all');

  Future<void> setMode(String mode) => sendCommand(
        cmd: 'set_mode',
        payload: {'mode': mode},
      );

  // ─── Auto Config ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAutoConfig({
    String deviceId = AppConstants.defaultDeviceId,
  }) async {
    return await _client
        .from(AppConstants.tableAutoConfig)
        .select()
        .eq('device_id', deviceId)
        .order('zone');
  }

  Future<void> updateAutoConfig({
    required String deviceId,
    required int zone,
    required double lowThresh,
    required double highThresh,
    required bool enabled,
  }) async {
    await _client.from(AppConstants.tableAutoConfig).upsert({
      'device_id': deviceId,
      'zone': zone,
      'low_thresh': lowThresh.round(),
      'high_thresh': highThresh.round(),
      'enabled': enabled,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'device_id,zone');
  }

  // ─── Realtime channel ────────────────────────────────────
  RealtimeChannel subscribeToCommands({
    required String deviceId,
    required void Function(Map<String, dynamic>) onInsert,
  }) {
    return _client.channel('commands:$deviceId').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: AppConstants.tableCommands,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'device_id',
        value: deviceId,
      ),
      callback: (payload) => onInsert(payload.newRecord),
    ).subscribe();
  }
}
