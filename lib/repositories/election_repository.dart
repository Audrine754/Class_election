import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

class ElectionRepository {
  ElectionRepository(this.uid);

  final String uid;

  // users/{uid}: the path your security rules protect.
  DocumentReference<Map<String, dynamic>> get _root =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _candidates =>
      _root.collection('candidates');

  CollectionReference<Map<String, dynamic>> get _voters =>
      _root.collection('voters');

  DocumentReference<Map<String, dynamic>> get _settings =>
      _root.collection('settings').doc('election');

  // ---------- The three pipes ----------
  Stream<List<Candidate>> watchCandidates() => _candidates
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Candidate.fromDoc).toList());

  // Oldest first: undo uses the last voter in the list.
  Stream<List<Voter>> watchVoters() => _voters
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(Voter.fromDoc).toList());

  Stream<int?> watchClassSize() => _settings
      .snapshots()
      .map((s) => (s.data()?['classSize'] as num?)?.toInt());

  // ---------- Writes (no checks here, only Firestore) ----------

  Future<void> addCandidate(String name) =>
      _candidates.add({'name': name, 'votes': 0});

  Future<void> deleteCandidate(String id) => _candidates.doc(id).delete();

  Future<void> setClassSize(int size) => _settings.set({'classSize': size});

  // One batch: record the voter AND add 1 to the candidate, all or nothing.
  Future<void> vote(String voterName, String candidateId) {
    final batch = FirebaseFirestore.instance.batch();
    batch.set(_voters.doc(), {
      'name': voterName,
      'candidateId': candidateId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_candidates.doc(candidateId), {
      'votes': FieldValue.increment(1),
    });
    return batch.commit();
  }

  // Delete the voter; take 1 off the candidate if that candidate still exists.
  Future<void> undoVote(Voter voter, {required bool candidateExists}) {
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_voters.doc(voter.id));
    if (candidateExists) {
      batch.update(_candidates.doc(voter.candidateId), {
        'votes': FieldValue.increment(-1),
      });
    }
    return batch.commit();
  }

  Future<void> resetVotes(List<Candidate> candidates, List<Voter> voters) {
    final batch = FirebaseFirestore.instance.batch();
    for (final v in voters) {
      batch.delete(_voters.doc(v.id));
    }
    for (final c in candidates) {
      batch.update(_candidates.doc(c.id), {'votes': 0});
    }
    return batch.commit();
  }

  Future<void> addSamples() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final name in ['Keza', 'Mutoni', 'Habimana']) {
      batch.set(_candidates.doc(), {'name': name, 'votes': 0});
    }
    await batch.commit();
  }
}