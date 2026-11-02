import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/election_state.dart';
import '../widgets.dart';

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key});

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

  Future<void> add() async {
    final election = context.read<ElectionState>(); // read BEFORE the await
    try {
      final error = await election.addCandidate(nameController.text);
      if (!mounted) return;
      if (error != null) {
        showMessage(context, error);
        return;
      }
      nameController.clear();
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Could not save. Check your internet connection.');
    }
  }

  Future<void> remove(Candidate candidate) async {
    final election = context.read<ElectionState>();
    try {
      final error = await election.removeCandidate(candidate);
      if (!mounted) return;
      if (error != null) showMessage(context, error);
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Could not delete. Check your internet connection.');
    }
  }

  Future<void> saveSize() async {
    final election = context.read<ElectionState>();
    try {
      final error = await election.setClassSize(sizeController.text);
      if (!mounted) return;
      if (error != null) {
        showMessage(context, error);
        return;
      }
      sizeController.clear();
      showMessage(context, 'Class size saved');
    } catch (e) {
      if (!mounted) return;
      showMessage(context, 'Could not save. Check your internet connection.');
    }
  }

  void confirmReset() {
    final election = context.read<ElectionState>();
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
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await election.resetVotes();
                  if (!mounted) return;
                  showMessage(context, 'All votes cleared');
                } catch (e) {
                  if (!mounted) return;
                  showMessage(
                      context, 'Could not reset. Check your internet connection.');
                }
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
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
    return Padding(
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
                    'Students in class (now: ${election.classSize ?? "not set"})',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final election = context.watch<ElectionState>(); // watch: rebuild on change
    return Scaffold(
      appBar: AppBar(title: const Text('Candidates')),
      body: _body(election),
    );
  }
}