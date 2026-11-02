import 'package:flutter/material.dart';

import 'weather.dart';

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

// ---------------- Live weather badge (API, three states) ----------------

class WeatherBadge extends StatefulWidget {
  const WeatherBadge({super.key});

  @override
  State<WeatherBadge> createState() => _WeatherBadgeState();
}

class _WeatherBadgeState extends State<WeatherBadge> {
  Weather? weather;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final result = await fetchWeather();
      if (!mounted) return;
      setState(() {
        weather = result;
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = 'Weather unavailable';
      });
    }
  }

  void retry() {
    setState(() {
      loading = true;
      error = null;
    });
    load();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (loading) {
      content = const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading the weather...'),
        ],
      );
    } else if (error != null) {
      content = Row(
        children: [
          const Icon(Icons.wifi_off),
          const SizedBox(width: 12),
          Expanded(child: Text(error!)),
          TextButton(onPressed: retry, child: const Text('Retry')),
        ],
      );
    } else {
      final w = weather!;
      content = Row(
        children: [
          Icon(w.code == 0 ? Icons.wb_sunny : Icons.cloud),
          const SizedBox(width: 12),
          Text(
            'Election day in Kigali: ${w.temperature.round()}°C, ${describe(w.code)}',
          ),
        ],
      );
    }
    return Card(
      child: Padding(padding: const EdgeInsets.all(12), child: content),
    );
  }
}