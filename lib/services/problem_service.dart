import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/problem.dart';

class ProblemService {
  static final ProblemService _instance = ProblemService._();
  factory ProblemService() => _instance;
  ProblemService._();

  final Map<int, List<Problem>> _cache = {};

  Future<List<Problem>> loadYear(int year) async {
    if (_cache.containsKey(year)) return _cache[year]!;

    try {
      final raw = await rootBundle.loadString('assets/data/${year}_trees.json');
      final List<dynamic> list = json.decode(raw) as List;
      final problems = list.map((e) => Problem.fromJson(e as Map<String, dynamic>)).toList();
      _cache[year] = problems;
      return problems;
    } catch (e) {
      return [];
    }
  }

  Future<List<Problem>> loadAll(List<int> years) async {
    final results = <Problem>[];
    for (final y in years) {
      results.addAll(await loadYear(y));
    }
    return results;
  }

  List<Problem> filterByUnit(List<Problem> problems, String unit) =>
      problems.where((p) => p.unit == unit).toList();

  List<Problem> filterByDifficulty(List<Problem> problems, String difficulty) =>
      problems.where((p) => p.difficulty == difficulty).toList();

  List<Problem> filterByYear(List<Problem> problems, int year) =>
      problems.where((p) => p.year == year).toList();

  List<String> getUnits(List<Problem> problems) =>
      problems.map((p) => p.unit).toSet().toList()..sort();

  static const List<int> availableYears = [
    2000, 2001, 2002, 2003, 2004,
    2005, 2006, 2007, 2008, 2009, 2010, 2011, 2012, 2013, 2014,
    2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024,
  ];
}
