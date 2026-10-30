import 'package:cloud_firestore/cloud_firestore.dart';

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

// ---------- Changes. Each returns null on success, or an error message.
// ---------- All the checks come first, the write comes last.

Future<String?> vote(
    String rawName,
    Candidate candidate,
    List<Voter> voters,
    ) async {
  final voter = cleanName(rawName);
  if (voter.isEmpty) return 'Please type your name';
  if (voters.any((v) => v.name == voter)) return '$voter has already voted';

  // One batch: record the voter AND add 1 to the candidate, all or nothing.
  final batch = FirebaseFirestore.instance.batch();
  batch.set(myVoters().doc(), {
    'name': voter,
    'candidateId': candidate.id,
    'createdAt': FieldValue.serverTimestamp(),
  });
  batch.update(myCandidates().doc(candidate.id), {
    'votes': FieldValue.increment(1),
  });
  await batch.commit();
  return null;
}

// Undo = do the opposite of the last vote.
Future<String> undoLastVote(
    List<Voter> voters,
    List<Candidate> candidates,
    ) async {
  if (voters.isEmpty) return 'No vote to undo';
  final last = voters.last; // voters arrive in order of time
  final matches = candidates.where((c) => c.id == last.candidateId);

  final batch = FirebaseFirestore.instance.batch();
  batch.delete(myVoters().doc(last.id)); // this person can vote again
  if (matches.isNotEmpty) {
    batch.update(myCandidates().doc(last.candidateId), {
      'votes': FieldValue.increment(-1),
    });
  }
  await batch.commit();

  final target = matches.isNotEmpty ? matches.first.name : 'a candidate';
  return 'Undid ${last.name}\'s vote for $target';
}

Future<String?> addCandidate(String rawName, List<Candidate> candidates) async {
  final name = cleanName(rawName);
  if (name.isEmpty) return 'Candidate name cannot be empty';
  if (candidates.any((c) => c.name == name)) return '$name is already a candidate';
  await myCandidates().add({'name': name, 'votes': 0});
  return null;
}

Future<String?> removeCandidate(Candidate candidate) async {
  if (candidate.votes > 0) {
    return '${candidate.name} has votes and cannot be removed';
  }
  await myCandidates().doc(candidate.id).delete();
  return null;
}

Future<String?> setClassSize(String raw, int voterCount) async {
  final size = int.tryParse(raw.trim());
  if (size == null || size <= 0) {
    return 'Class size must be a whole number above 0';
  }
  if (size < voterCount) {
    return 'Class size cannot be smaller than the $voterCount votes already cast';
  }
  await myElectionSettings().set({'classSize': size});
  return null;
}

// Clear every vote: delete all voters and put every candidate back to 0.
Future<void> resetVotes(List<Candidate> candidates, List<Voter> voters) async {
  final batch = FirebaseFirestore.instance.batch();
  for (final v in voters) {
    batch.delete(myVoters().doc(v.id));
  }
  for (final c in candidates) {
    batch.update(myCandidates().doc(c.id), {'votes': 0});
  }
  await batch.commit();
}

// Sample data, written once when a new account is created
Future<void> addSampleCandidates() async {
  final batch = FirebaseFirestore.instance.batch();
  for (final name in ['Keza', 'Mutoni', 'Habimana']) {
    batch.set(myCandidates().doc(), {'name': name, 'votes': 0});
  }
  await batch.commit();
}