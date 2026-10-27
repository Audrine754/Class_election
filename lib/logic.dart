import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

// Trim, remove extra spaces, Title Case: '  keza   uwase ' -> 'Keza Uwase'
String cleanName(String raw) {
  final words = raw
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase());
  return words.join(' ');
}

class Election {
  final List<Candidate> candidates = [
    Candidate(name: 'Keza'),
    Candidate(name: 'Mutoni'),
    Candidate(name: 'Habimana'),
  ];
  final List<String> voters = []; // cleaned names of people who voted
  final List<VoteRecord> history = []; // every vote, in order
  int? classSize; // typed by the user; null until set

  int get totalVotes {
    int total = 0;
    for (final c in candidates) {
      total += c.votes;
    }
    return total;
  }

  // ---------- Saving ----------

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'candidates': candidates.map((c) => c.toJson()).toList(),
      'voters': voters,
      'history': history
          .map((h) => {'voter': h.voter, 'candidate': h.candidate.name})
          .toList(),
      'classSize': classSize,
    };
    await prefs.setString('election', jsonEncode(data));
  }

  // First time: nothing saved, so the sample data stays.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('election');
    if (saved == null) return;

    final data = jsonDecode(saved) as Map<String, dynamic>;

    candidates.clear();
    for (final x in data['candidates'] as List) {
      candidates.add(Candidate.fromJson(x as Map<String, dynamic>));
    }

    voters.clear();
    for (final x in data['voters'] as List) {
      voters.add(x as String);
    }

    history.clear();
    for (final x in data['history'] as List) {
      final m = x as Map<String, dynamic>;
      final matches = candidates.where((c) => c.name == m['candidate']);
      if (matches.isNotEmpty) {
        history.add(
          VoteRecord(voter: m['voter'] as String, candidate: matches.first),
        );
      }
    }

    classSize = data['classSize'] as int?;
  }

  // ---------- Rules (null = success, otherwise an error message) ----------

  String? vote(String rawName, Candidate candidate) {
    final voter = cleanName(rawName);
    if (voter.isEmpty) return 'Please type your name';
    if (voters.contains(voter)) return '$voter has already voted';
    voters.add(voter);
    candidate.votes++;
    history.add(VoteRecord(voter: voter, candidate: candidate));
    return null;
  }

  String undoLastVote() {
    if (history.isEmpty) return 'No vote to undo';
    final last = history.removeLast();
    last.candidate.votes--;
    voters.remove(last.voter);
    return 'Undid ${last.voter}\'s vote for ${last.candidate.name}';
  }

  String? addCandidate(String rawName) {
    final name = cleanName(rawName);
    if (name.isEmpty) return 'Candidate name cannot be empty';
    final exists = candidates.any((c) => c.name == name);
    if (exists) return '$name is already a candidate';
    candidates.add(Candidate(name: name));
    return null;
  }

  String? removeCandidate(Candidate candidate) {
    if (candidate.votes > 0) {
      return '${candidate.name} has votes and cannot be removed';
    }
    candidates.remove(candidate);
    return null;
  }

  String? setClassSize(String raw) {
    final size = int.tryParse(raw.trim());
    if (size == null || size <= 0) {
      return 'Class size must be a whole number above 0';
    }
    if (size < voters.length) {
      return 'Class size cannot be smaller than the ${voters.length} votes already cast';
    }
    classSize = size;
    return null;
  }

  String turnoutText() {
    if (classSize == null) {
      return 'Turnout: set the class size on the Candidates screen';
    }
    final pct = voters.length / classSize! * 100;
    return 'Turnout: ${voters.length} of $classSize students (${pct.toStringAsFixed(1)}%)';
  }

  // ---------- Results ----------

  double percent(Candidate candidate) {
    if (totalVotes == 0) return 0; // avoids 0 / 0 = NaN
    return candidate.votes / totalVotes * 100;
  }

  // A sorted COPY, so the real list keeps its order.
  List<Candidate> ranked() {
    final copy = List<Candidate>.from(candidates);
    copy.sort((a, b) {
      if (b.votes != a.votes) return b.votes.compareTo(a.votes);
      return a.name.compareTo(b.name);
    });
    return copy;
  }

  String bannerText() {
    if (totalVotes == 0) return 'No votes yet';
    final top = ranked().first.votes;
    final leaders = candidates.where((c) => c.votes == top).toList();
    if (leaders.length == 1) return 'Winner: ${leaders.first.name}';
    final names = leaders.map((c) => c.name).toList();
    final last = names.removeLast();
    return 'Tie between ${names.join(', ')} and $last ($top votes each)';
  }

  void reset() {
    for (final c in candidates) {
      c.votes = 0;
    }
    voters.clear();
    history.clear();
  }
}