import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await SupabaseService.getHistory();
    setState(() { _logs = logs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử tưới')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _logs.isEmpty
          ? const Center(child: Text('Chưa có lịch sử'))
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (ctx, i) {
                final log = _logs[i];
                final time = DateTime.parse(log['created_at']).toLocal();
                final fmt  = DateFormat('dd/MM HH:mm').format(time);
                return ListTile(
                  leading: const Icon(Icons.water_drop, color: Colors.blue),
                  title: Text(log['action'] ?? ''),
                  subtitle: Text(fmt),
                  trailing: Text('${log['soil_pct'] ?? 0}%'),
                );
              },
            ),
    );
  }
}