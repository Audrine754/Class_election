import 'dart:async';

import 'package:flutter/foundation.dart';

import '../logic.dart' show cleanName;
import '../models/models.dart';
import '../repositories/election_repository.dart';

class ElectionState extends ChangeNotifier {
  ElectionState(this._repo) {
    // Born: open the three pipes, once.
    _candidatesSub = _repo.watchCandidates().listen((list) {
      _candidates = list;
      _candidatesReady = true;
      _error = null;
      notifyListeners();
    }, onError: _onError);

    _votersSub = _repo.watchVoters().listen((list) {
      _voters = list;
      _votersReady = true;
      _error = null;
      notifyListeners();
    }, onError: _onError);

    _settingsSub = _repo.watchClassSize().listen((size) {
      _classSize = size;
      _settingsReady = true;
      _error = null;
      notifyListeners();
    }, onError: _onError);
  }

  final ElectionRepository _repo;
  StreamSubscription<List<Candidate>>? _candidatesSub;
  StreamSubscription<List<Voter>>? _votersSub;
  StreamSubscription<int?>? _settingsSub;

  // The data: private, so only the brain can change it.
  List<Candidate> _candidates = [];
  List<Voter> _voters = [];
  int? _classSize;
  bool _candidatesReady = false;
  bool _votersReady = false;
  bool _settingsReady = false;
  String? _error;

  void _onError(Object e) {
    _error = 'Could not load the election.';
    notifyListeners();
  }

  // Read-only views for the screens.
  List<Candidate> get candidates => _candidates;
  List<Voter> get voters => _voters;
  int? get classSize => _classSize;
  String? get error => _error;
  bool get loading => !_candidatesReady || !_votersReady || !_settingsReady;

  // Computed every time it is read, never saved.
  int get totalVotes => _candidates.fold<int>(0, (sum, c) => sum + c.votes);

  // Actions: checks first, then the repository does the write.
  // Each returns null on success, or an error message.
  Future<String?> vote(String rawName, Candidate candidate) async {
    final voter = cleanName(rawName);
    if (voter.isEmpty) return 'Please type your name';
    if (_voters.any((v) => v.name == voter)) return '$voter has already voted';
    await _repo.vote(voter, candidate.id);
    return null;
  }

  Future<String> undoLastVote() async {
    if (_voters.isEmpty) return 'No vote to undo';
    final last = _voters.last; // oldest first, so last = most recent
    final matches = _candidates.where((c) => c.id == last.candidateId);
    await _repo.undoVote(last, candidateExists: matches.isNotEmpty);
    final target = matches.isNotEmpty ? matches.first.name : 'a candidate';
    return 'Undid ${last.name}\'s vote for $target';
  }

  Future<String?> addCandidate(String rawName) async {
    final name = cleanName(rawName);
    if (name.isEmpty) return 'Candidate name cannot be empty';
    if (_candidates.any((c) => c.name == name)) {
      return '$name is already a candidate';
    }
    await _repo.addCandidate(name);
    return null;
  }

  Future<String?> removeCandidate(Candidate candidate) async {
    if (candidate.votes > 0) {
      return '${candidate.name} has votes and cannot be removed';
    }
    await _repo.deleteCandidate(candidate.id);
    return null;
  }

  Future<String?> setClassSize(String raw) async {
    final size = int.tryParse(raw.trim());
    if (size == null || size <= 0) {
      return 'Class size must be a whole number above 0';
    }
    if (size < _voters.length) {
      return 'Class size cannot be smaller than the ${_voters.length} votes already cast';
    }
    await _repo.setClassSize(size);
    return null;
  }

  Future<void> resetVotes() => _repo.resetVotes(_candidates, _voters);

  @override
  void dispose() {
    _candidatesSub?.cancel();
    _votersSub?.cancel();
    _settingsSub?.cancel();
    super.dispose();
  }
}