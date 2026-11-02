import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic.dart' show ranked, percent, bannerText, turnoutText;
import '../state/election_state.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final election = context.watch<ElectionState>(); // watch: rebuild on change
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: _body(context, election),
    );
  }

  Widget _body(BuildContext context, ElectionState election) {
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
    final list = ranked(candidates);
    final total = election.totalVotes;
    return Padding(
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
              bannerText(candidates),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            turnoutText(election.voters.length, election.classSize),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No candidates yet'))
                : ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final c = list[index];
                final pct = percent(c, total);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${c.name}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text('${c.votes} votes · ${pct.toStringAsFixed(1)}%'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: pct / 100,
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
    );
  }
}