import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import 'supabase_service.dart';
import 'package:get/get.dart';

/// RealtimeService — Quản lý Supabase Realtime subscriptions
class RealtimeService extends GetxService {
  final SupabaseClient _client = Supabase.instance.client;
  final _supabaseService = Get.find<SupabaseService>();

  RealtimeChannel? _valveChannel;
  RealtimeChannel? _sensorChannel;

  // ─── Subscribe trạng thái van (realtime) ─────────────────
  RealtimeChannel subscribeValveStatus({
    required String deviceId,
    required void Function(Map<String, dynamic>) onUpdate,
  }) {
    _valveChannel?.unsubscribe();
    _valveChannel = _client
        .channel('valve_status:$deviceId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: AppConstants.tableValveStatus,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'device_id',
            value: deviceId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();
    return _valveChannel!;
  }

  // ─── Subscribe sensor logs mới nhất ──────────────────────
  RealtimeChannel subscribeSensorLogs({
    required String deviceId,
    required void Function(Map<String, dynamic>) onInsert,
  }) {
    _sensorChannel?.unsubscribe();
    _sensorChannel = _client
        .channel('sensor_logs:$deviceId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: AppConstants.tableSensorLogs,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'device_id',
            value: deviceId,
          ),
          callback: (payload) => onInsert(payload.newRecord),
        )
        .subscribe();
    return _sensorChannel!;
  }

  // ─── Hủy tất cả subscriptions ────────────────────────────
  void unsubscribeAll() {
    _valveChannel?.unsubscribe();
    _sensorChannel?.unsubscribe();
    _valveChannel = null;
    _sensorChannel = null;
  }

  @override
  void onClose() {
    unsubscribeAll();
    super.onClose();
  }
}
