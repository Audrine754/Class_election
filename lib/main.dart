import 'package:flutter/material.dart';

import 'logic.dart';
import 'models.dart';
import 'weather.dart';

void main() {
  runApp(const ElectionApp());
}

class ElectionApp extends StatelessWidget {
  const ElectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Class Election',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const VoteScreen(),
    );
  }
}

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

// ---------------- Screen 1: Vote ----------------

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final election = Election(); // the one shared set of data
  final nameController = TextEditingController();
  bool ready = false; // false while the saved data loads

  @override
  void initState() {
    super.initState();
    loadSaved();
  }

  Future<void> loadSaved() async {
    await election.load();
    if (!mounted) return;
    setState(() {
      ready = true;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void castVote(Candidate candidate) {
    final voter = cleanName(nameController.text);
    final error = election.vote(nameController.text, candidate);
    if (error != null) {
      showMessage(context, error);
      return;
    }
    election.save();
    setState(() {
      nameController.clear();
    });
    showMessage(context, '$voter voted for ${candidate.name}');
  }

  void undo() {
    final message = election.undoLastVote();
    election.save();
    setState(() {});
    showMessage(context, message);
  }

  void openResults() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ResultsScreen(election: election)),
    );
  }

  void openCandidates() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CandidatesScreen(election: election),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Election'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo last vote',
            onPressed: undo,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Results',
            onPressed: openResults,
          ),
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Candidates',
            onPressed: openCandidates,
          ),
        ],
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const WeatherBadge(),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Votes so far: ${election.totalVotes}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: election.candidates.isEmpty
                  ? const Center(
                child: Text('No candidates yet. Add one first.'),
              )
                  : ListView.builder(
                itemCount: election.candidates.length,
                itemBuilder: (context, index) {
                  final candidate = election.candidates[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(candidate.name),
                      trailing: FilledButton(
                        onPressed: () => castVote(candidate),
                        child: const Text('Vote'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Screen 2: Results ----------------

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.election});

  final Election election;

  @override
  Widget build(BuildContext context) {
    final ranked = election.ranked();
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                election.bannerText(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            const SizedBox(height: 16),
            Text(election.turnoutText(), style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(
              child: ranked.isEmpty
                  ? const Center(child: Text('No candidates yet'))
                  : ListView.builder(
                itemCount: ranked.length,
                itemBuilder: (context, index) {
                  final c = ranked[index];
                  final percent = election.percent(c);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}. ${c.name}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        Text(
                          '${c.votes} votes · ${percent.toStringAsFixed(1)}%',
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percent / 100,
                          minHeight: 12,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Screen 3: Candidates ----------------

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key, required this.election});

  final Election election;

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  final nameController = TextEditingController();
  final sizeController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    sizeController.dispose();
    super.dispose();
  }

  void add() {
    final error = widget.election.addCandidate(nameController.text);
    if (error != null) {
      showMessage(context, error);
      return;
    }
    widget.election.save();
    setState(() {
      nameController.clear();
    });
  }

  void remove(Candidate candidate) {
    final error = widget.election.removeCandidate(candidate);
    if (error != null) {
      showMessage(context, error);
      return;
    }
    widget.election.save();
    setState(() {});
  }

  void saveSize() {
    final error = widget.election.setClassSize(sizeController.text);
    if (error != null) {
      showMessage(context, error);
      return;
    }
    widget.election.save();
    setState(() {
      sizeController.clear();
    });
    showMessage(context, 'Class size set to ${widget.election.classSize}');
  }

  void confirmReset() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset all votes?'),
          content: const Text(
            'Every vote will be cleared. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                widget.election.reset();
                widget.election.save();
                setState(() {});
                Navigator.pop(dialogContext);
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final candidates = widget.election.candidates;
    return Scaffold(
      appBar: AppBar(title: const Text('Candidates')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'New candidate',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: add, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sizeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText:
                      'Students in class (now: ${widget.election.classSize ?? "not set"})',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: saveSize, child: const Text('Set')),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: candidates.isEmpty
                  ? const Center(child: Text('No candidates yet'))
                  : ListView.builder(
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final c = candidates[index];
                  return ListTile(
                    title: Text(c.name),
                    subtitle: Text('${c.votes} votes'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => remove(c),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: confirmReset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reset all votes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}