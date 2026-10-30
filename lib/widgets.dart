import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'weather.dart';

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

// Listens to the three pieces of the election in Firestore and gives them to
// `builder` every time any of them changes. It also shows the loading and
// error states, so each screen only has to draw the data.
class ElectionBuilder extends StatefulWidget {
  const ElectionBuilder({super.key, required this.builder});

  final Widget Function(
      BuildContext context,
      List<Candidate> candidates,
      List<Voter> voters,
      int? classSize,
      ) builder;

  @override
  State<ElectionBuilder> createState() => _ElectionBuilderState();
}

class _ElectionBuilderState extends State<ElectionBuilder> {
  // Created once in initState, so the streams are not restarted on every rebuild.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> candidatesStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> votersStream;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> settingsStream;

  @override
  void initState() {
    super.initState();
    candidatesStream = myCandidates().orderBy('name').snapshots();
    votersStream = myVoters().orderBy('createdAt').snapshots();
    settingsStream = myElectionSettings().snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: candidatesStream,
      builder: (context, candidatesSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: votersStream,
          builder: (context, votersSnap) {
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: settingsStream,
              builder: (context, settingsSnap) {
                final error =
                    candidatesSnap.error ?? votersSnap.error ?? settingsSnap.error;
                if (error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load the election.\n$error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!candidatesSnap.hasData ||
                    !votersSnap.hasData ||
                    !settingsSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final candidates =
                candidatesSnap.data!.docs.map(Candidate.fromDoc).toList();
                final voters = votersSnap.data!.docs.map(Voter.fromDoc).toList();
                final classSize =
                (settingsSnap.data!.data()?['classSize'] as num?)?.toInt();
                return widget.builder(context, candidates, voters, classSize);
              },
            );
          },
        );
      },
    );
  }
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