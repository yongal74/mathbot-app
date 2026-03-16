import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/wrong_note.dart';
import '../models/problem.dart';

class WrongNoteService extends ChangeNotifier {
  static final WrongNoteService _i = WrongNoteService._();
  factory WrongNoteService() => _i;
  WrongNoteService._();

  final Map<String, WrongNote> _notes = {};
  static const _key = 'wrong_notes';

  List<WrongNote> get all => _notes.values.toList()
    ..sort((a, b) => b.savedAt.compareTo(a.savedAt));

  bool has(String problemId) => _notes.containsKey(problemId);
  WrongNote? get(String problemId) => _notes[problemId];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = json.decode(raw) as List;
      for (final e in list) {
        final note = WrongNote.fromJson(e as Map<String, dynamic>);
        _notes[note.problemId] = note;
      }
    }
    notifyListeners();
  }

  Future<void> add(Problem problem, {List<String> weakNodes = const []}) async {
    _notes[problem.id] = WrongNote(
      problemId: problem.id,
      year: problem.year,
      no: problem.no,
      unit: problem.unit,
      difficulty: problem.difficulty,
      savedAt: DateTime.now(),
      weakNodes: weakNodes,
    );
    await _save();
    notifyListeners();
  }

  Future<void> remove(String problemId) async {
    _notes.remove(problemId);
    await _save();
    notifyListeners();
  }

  Future<void> updateMemo(String problemId, String memo) async {
    final note = _notes[problemId];
    if (note == null) return;
    _notes[problemId] = note.copyWith(memo: memo);
    await _save();
    notifyListeners();
  }

  Future<void> updateWeakNodes(String problemId, List<String> weakNodes) async {
    final note = _notes[problemId];
    if (note == null) return;
    _notes[problemId] = note.copyWith(weakNodes: weakNodes);
    await _save();
    notifyListeners();
  }

  Future<void> markReviewed(String problemId) async {
    final note = _notes[problemId];
    if (note == null) return;
    _notes[problemId] = note.copyWith(reviewCount: note.reviewCount + 1);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(all.map((n) => n.toJson()).toList()));
  }

  Map<String, int> get unitWeakness {
    final map = <String, int>{};
    for (final n in _notes.values) {
      map[n.unit] = (map[n.unit] ?? 0) + 1;
    }
    return map;
  }
}
