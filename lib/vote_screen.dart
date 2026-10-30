import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'candidates_screen.dart';
import 'logic.dart';
import 'models.dart';
import 'results_screen.dart';
import 'widgets.dart';

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

  Future<void> castVote(Candidate candidate, List<Voter> voters) async {
    if (saving) return;
    saving = true;
    final voterName = cleanName(nameController.text);
    try {
      final error = await vote(nameController.text, candidate, voters);
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

  Future<void> undo(List<Voter> voters, List<Candidate> candidates) async {
    try {
      final message = await undoLastVote(voters, candidates);
      if (!mounted) return;
      showMessage(context, message);
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Could not undo. Check your internet connection.');
    }
  }

  void openResults() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResultsScreen()),
    );
  }

  void openCandidates() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CandidatesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Expanded(
              child: ElectionBuilder(
                builder: (context, candidates, voters, classSize) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Votes so far: ${totalVotes(candidates)}',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => undo(voters, candidates),
                            icon: const Icon(Icons.undo),
                            label: const Text('Undo last vote'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: candidates.isEmpty
                            ? const Center(
                          child: Text('No candidates yet. Add one first.'),
                        )
                            : ListView.builder(
                          itemCount: candidates.length,
                          itemBuilder: (context, index) {
                            final candidate = candidates[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.person),
                                title: Text(candidate.name),
                                trailing: FilledButton(
                                  onPressed: () =>
                                      castVote(candidate, voters),
                                  child: const Text('Vote'),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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