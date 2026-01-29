// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; });
    final data = await ApiService.fetchHistory();
    setState(() {
      history = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (history.isEmpty) return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("No predicted history yet"),
      ElevatedButton(onPressed: _load, child: const Text("Refresh"))
    ]));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final item = history[i] as Map<String, dynamic>;
          final risk = (item['risk_level'] ?? 'unknown').toString();
          final score = item['risk_score']?.toString() ?? '-';
          final temp = item['temperature']?.toString() ?? '-';
          final hum = item['humidity']?.toString() ?? '-';
          final rain = item['rainfall']?.toString() ?? '-';
          final sun = item['sunshine']?.toString() ?? '-';
          final at = (item['predicted_at'] ?? item['sensor_created_at'])?.toString() ?? '-';

          return Card(
            child: ListTile(
              title: Text("Risk: ${risk.toUpperCase()}  (score: $score)"),
              subtitle: Text("T:$temp °C  H:$hum%  R:$rain mm  S:$sun h\nAt: $at"),
            ),
          );
        },
      ),
    );
  }
}
