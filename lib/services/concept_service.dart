import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/problem.dart';

class PracticeEntry {
  final String concept;
  final String subject;
  final List<PracticeProblem> problems;
  final Map<String, dynamic>? explanation;

  const PracticeEntry({
    required this.concept,
    required this.subject,
    required this.problems,
    this.explanation,
  });
}

class PracticeProblem {
  final String difficulty;
  final String question;
  final String answerValue;
  final String hint;
  final List<TreeNode> nodes;
  final bool verified;

  const PracticeProblem({
    required this.difficulty,
    required this.question,
    required this.answerValue,
    required this.hint,
    required this.nodes,
    this.verified = false,
  });

  factory PracticeProblem.fromJson(Map<String, dynamic> json) => PracticeProblem(
        difficulty: json['difficulty'] as String? ?? '중',
        question: json['question'] as String? ?? '',
        answerValue: json['answer_value'] as String? ?? '',
        hint: json['hint'] as String? ?? '',
        nodes: (json['nodes'] as List? ?? [])
            .map((e) => TreeNode.fromJson(e as Map<String, dynamic>))
            .toList(),
        verified: json['verified'] as bool? ?? false,
      );
}

class ConceptService {
  static final ConceptService _instance = ConceptService._();
  factory ConceptService() => _instance;
  ConceptService._();

  Map<String, PracticeEntry>? _cache;

  Future<Map<String, PracticeEntry>> loadAll() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString('assets/data/practice_problems.json');
      final Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;
      _cache = data.map((key, value) {
        final v = value as Map<String, dynamic>;
        final problems = (v['problems'] as List? ?? [])
            .map((e) => PracticeProblem.fromJson(e as Map<String, dynamic>))
            .toList();
        return MapEntry(key, PracticeEntry(
          concept: key,
          subject: v['subject'] as String? ?? '',
          problems: problems,
          explanation: v['explanation'] as Map<String, dynamic>?,
        ));
      });
    } catch (_) {
      _cache = {};
    }
    return _cache!;
  }

  Future<PracticeEntry?> loadConcept(String concept) async {
    final all = await loadAll();
    return all[concept];
  }
}
