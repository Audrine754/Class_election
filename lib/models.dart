class Candidate {
  final String name; // never edited, so final
  int votes; // changes with every vote, so NOT final

  Candidate({required this.name, this.votes = 0});

  Map<String, dynamic> toJson() {
    return {'name': name, 'votes': votes};
  }

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      name: json['name'] as String,
      votes: json['votes'] as int,
    );
  }
}

// One vote, remembered so it can be undone
class VoteRecord {
  final String voter;
  final Candidate candidate;

  VoteRecord({required this.voter, required this.candidate});
}