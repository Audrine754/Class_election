import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic.dart' show cleanName;
import '../models/models.dart';
import '../state/election_state.dart';
import '../widgets.dart';
import 'candidates_screen.dart';
import 'results_screen.dart';

class VoteScreen extends StatefulWidget {
  const VoteScreen({super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final nameController = TextEditingController();
  bool saving = false; // stops a double tap from voting twice

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> castVote(Candidate candidate) async {
    if (saving) return;
    saving = true;
    final election = context.read<ElectionState>(); // read BEFORE the await
    final voterName = cleanName(nameController.text);
    try {
      final error = await election.vote(nameController.text, candidate);
      if (!mounted) return;
      if (error != null) {
        showMessage(context, error);
        return;
      }
      nameController.clear();
      showMessage(context, '$voterName voted for ${candidate.name}');
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Could not save your vote. Check your internet connection.');
    } finally {
      saving = false;
    }
  }

  Future<void> undo() async {
    final election = context.read<ElectionState>(); // read BEFORE the await
    try {
      final message = await election.undoLastVote();
      if (!mounted) return;
      showMessage(context, message);
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Could not undo. Check your internet connection.');
    }
  }

  // Open a screen and hand it the SAME brain.
  void openResults() {
    final election = context.read<ElectionState>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ElectionState>.value(
          value: election,
          child: const ResultsScreen(),
        ),
      ),
    );
  }

  void openCandidates() {
    final election = context.read<ElectionState>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider<ElectionState>.value(
          value: election,
          child: const CandidatesScreen(),
        ),
      ),
    );
  }

  Widget _body(ElectionState election) {
    if (election.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(election.error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (election.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final candidates = election.candidates;
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Votes so far: ${election.totalVotes}',
              style: const TextStyle(fontSize: 18),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: undo,
              icon: const Icon(Icons.undo),
              label: const Text('Undo last vote'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: candidates.isEmpty
              ? const Center(child: Text('No candidates yet. Add one first.'))
              : ListView.builder(
            itemCount: candidates.length,
            itemBuilder: (context, index) {
              final candidate = candidates[index];
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final election = context.watch<ElectionState>(); // watch: rebuild on change
    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Election'),
        actions: [
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
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Padding(
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
            Expanded(child: _body(election)),
          ],
        ),
      ),
    );
  }
}