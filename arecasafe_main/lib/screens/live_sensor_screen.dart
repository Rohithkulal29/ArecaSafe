// lib/screens/live_sensor_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/sensor_card.dart';

class LiveSensorScreen extends StatefulWidget {
  const LiveSensorScreen({super.key});
  @override
  State<LiveSensorScreen> createState() => _LiveSensorScreenState();
}

class _LiveSensorScreenState extends State<LiveSensorScreen> {
  Map<String, dynamic>? live;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; });
    final data = await ApiService.fetchLiveSensor();
    if (data.isNotEmpty) {
      setState(() {
        live = data.first as Map<String, dynamic>;
      });
    } else {
      setState(() { live = null; });
    }
    setState(() { loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (live == null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("No live sensor data"),
        ElevatedButton(onPressed: _load, child: const Text("Refresh"))
      ]));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SensorCard(label: "Temperature", value: "${live!['temperature'] ?? '-'} °C"),
          SensorCard(label: "Humidity", value: "${live!['humidity'] ?? '-'} %"),
          SensorCard(label: "Rainfall", value: "${live!['rainfall'] ?? '-'} mm"),
          SensorCard(label: "Sunshine", value: "${live!['sunshine'] ?? '-'} h"),
          const SizedBox(height: 12),
          Text("Recorded at: ${live!['created_at'] ?? live!['timestamp'] ?? '-'}", style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
