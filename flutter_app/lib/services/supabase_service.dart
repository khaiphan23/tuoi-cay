import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';

class SupabaseService {
  static final _db = Supabase.instance.client;

  // Gửi lệnh xuống ESP32
  static Future<void> sendCommand(String command) async {
    await _db.from('commands').insert({
      'device_id': deviceId,
      'command':   command,
      'executed':  false,
    });
  }

  // Lắng nghe trạng thái realtime
  static Stream<Map<String, dynamic>> watchState() {
    return _db
        .from('system_state')
        .stream(primaryKey: ['id'])
        .eq('device_id', deviceId)
        .map((rows) => rows.isNotEmpty ? rows.first : {});
  }

  // Lấy lịch sử tưới
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final res = await _db
        .from('irrigation_logs')
        .select()
        .eq('device_id', deviceId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(res);
  }
}