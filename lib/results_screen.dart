import 'package:flutter/material.dart';

import 'logic.dart';
import 'widgets.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: ElectionBuilder(
        builder: (context, candidates, voters, classSize) {
          final list = ranked(candidates);
          final total = totalVotes(candidates);
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
                  turnoutText(voters.length, classSize),
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
                            Text(
                              '${c.votes} votes · ${pct.toStringAsFixed(1)}%',
                            ),
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
        },
      ),
    );
  }
}