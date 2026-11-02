import 'models/models.dart';

// Trim, remove extra spaces, Title Case: '  keza   uwase ' -> 'Keza Uwase'
String cleanName(String raw) {
  final words = raw
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase());
  return words.join(' ');
}

// ---------- Worked out from the data every time, never saved ----------

int totalVotes(List<Candidate> candidates) {
  int total = 0;
  for (final c in candidates) {
    total += c.votes;
  }
  return total;
}

double percent(Candidate candidate, int total) {
  if (total == 0) return 0; // avoids 0 / 0 = NaN
  return candidate.votes / total * 100;
}

// A sorted COPY, so the real list keeps its order.
List<Candidate> ranked(List<Candidate> candidates) {
  final copy = List<Candidate>.from(candidates);
  copy.sort((a, b) {
    if (b.votes != a.votes) return b.votes.compareTo(a.votes);
    return a.name.compareTo(b.name);
  });
  return copy;
}

String bannerText(List<Candidate> candidates) {
  if (totalVotes(candidates) == 0) return 'No votes yet';
  final top = ranked(candidates).first.votes; // the top score
  final leaders = candidates.where((c) => c.votes == top).toList();
  if (leaders.length == 1) return 'Winner: ${leaders.first.name}';
  final names = leaders.map((c) => c.name).toList();
  final last = names.removeLast();
  return 'Tie between ${names.join(', ')} and $last ($top votes each)';
}

String turnoutText(int voterCount, int? classSize) {
  if (classSize == null) {
    return 'Turnout: set the class size on the Candidates screen';
  }
  final pct = voterCount / classSize * 100;
  return 'Turnout: $voterCount of $classSize students (${pct.toStringAsFixed(1)}%)';
}