import 'models.dart';


String cleanName(String raw) {
  final words = raw
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty) //
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase());
  return words.join(' ');
}

class Election {
  final List<Candidate> candidates = [
    Candidate(name: 'Keza'),
    Candidate(name: 'Mutoni'),
    Candidate(name: 'Habimana'),
  ];
  final List<String> voters = [];

  int get totalVotes {
    int total = 0;
    for (final c in candidates) {
      total += c.votes;
    }
    return total;
  }


  String? vote(String rawName, Candidate candidate) {
    final voter = cleanName(rawName);
    if (voter.isEmpty) return 'Please type your name';
    if (voters.contains(voter)) return '$voter has already voted';
    voters.add(voter);
    candidate.votes++;
    return null;
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


  double percent(Candidate candidate) {
    if (totalVotes == 0) return 0;
    return candidate.votes / totalVotes * 100;
  }


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
  }
}