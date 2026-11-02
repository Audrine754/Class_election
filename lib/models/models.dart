import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Candidate {
  Candidate({this.id = '', required this.name, this.votes = 0});

  final String id; // the Firestore document id
  final String name;
  // Both fields are final now: the screen never changes them,
  // Firestore does, and the screen redraws when the data arrives.
  final int votes;

  Map<String, dynamic> toMap() => {'name': name, 'votes': votes};

  factory Candidate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Candidate(
      id: doc.id,
      name: data['name'] as String,
      votes: (data['votes'] as num).toInt(),
    );
  }
}

// One person who voted. Kept so nobody votes twice, and so a vote can be undone.
class Voter {
  Voter({
    required this.id,
    required this.name,
    required this.candidateId,
    this.createdAt,
  });

  final String id;
  final String name; // already cleaned
  final String candidateId; // who they voted for
  final DateTime? createdAt;

  factory Voter.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Voter(
      id: doc.id,
      name: data['name'] as String,
      candidateId: data['candidateId'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// Everything lives under users/{uid}/..., exactly where the rules allow.
DocumentReference<Map<String, dynamic>> _myRoot() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance.collection('users').doc(uid);
}

CollectionReference<Map<String, dynamic>> myCandidates() =>
    _myRoot().collection('candidates');

CollectionReference<Map<String, dynamic>> myVoters() =>
    _myRoot().collection('voters');

// One small document holding the class size
DocumentReference<Map<String, dynamic>> myElectionSettings() =>
    _myRoot().collection('settings').doc('election');