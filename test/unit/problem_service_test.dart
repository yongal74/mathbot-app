import 'package:flutter_test/flutter_test.dart';
import 'package:mathbot_app/services/problem_service.dart';
import 'package:mathbot_app/models/problem.dart';

// 테스트용 Problem 생성 헬퍼
Problem _p(String id, int year, int no, String unit, String difficulty) =>
    Problem(
      id: id,
      year: year,
      no: no,
      unit: unit,
      difficulty: difficulty,
      answer: '1',
      problemText: '',
      problemType: '단답형',
      choices: [],
      subject: '',
      concepts: [],
      nodeDepth: 3,
      nodes: [],
      optimalPath: '',
      commonMistake: '',
      hints: [],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final svc = ProblemService();

  final testProblems = [
    _p('p1', 2024, 1, '수열', '하'),
    _p('p2', 2024, 30, '미적분', '상'),
    _p('p3', 2023, 1, '수열', '중'),
    _p('p4', 2022, 15, '확률', '중'),
    _p('p5', 2020, 28, '미적분', '상'),
  ];

  group('ProblemService 필터 (TDD)', () {
    test('filterByUnit: 수열 = 2개', () {
      final result = svc.filterByUnit(testProblems, '수열');
      expect(result.length, 2);
      expect(result.every((p) => p.unit == '수열'), isTrue);
    });

    test('filterByDifficulty: 상 = 2개', () {
      final result = svc.filterByDifficulty(testProblems, '상');
      expect(result.length, 2);
    });

    test('filterByYear: 2024 = 2개', () {
      final result = svc.filterByYear(testProblems, 2024);
      expect(result.length, 2);
    });

    test('filterByYearRange: 2022~2023 = 2개', () {
      final result = svc.filterByYearRange(testProblems, 2022, 2023);
      expect(result.length, 2);
      expect(result.every((p) => p.year >= 2022 && p.year <= 2023), isTrue);
    });

    test('getUnits: 중복 제거 후 정렬', () {
      final units = svc.getUnits(testProblems);
      expect(units.toSet().length, units.length); // 중복 없음
      expect(units, equals([...units]..sort())); // 정렬됨
    });
  });

  group('ProblemService 정렬 (TDD)', () {
    test('sortByYear(desc): 2024 먼저', () {
      final sorted = svc.sortByYear(testProblems, descending: true);
      expect(sorted.first.year, 2024);
      expect(sorted.last.year, 2020);
    });

    test('sortByYear(asc): 2020 먼저', () {
      final sorted = svc.sortByYear(testProblems, descending: false);
      expect(sorted.first.year, 2020);
    });

    test('sortByDifficulty: 상→중→하 순서', () {
      final sorted = svc.sortByDifficulty(testProblems);
      expect(sorted.first.difficulty, '상');
      expect(sorted.last.difficulty, '하');
    });

    test('sortByProblemNumber: 오름차순', () {
      final sorted = svc.sortByProblemNumber(testProblems);
      for (int i = 0; i < sorted.length - 1; i++) {
        if (sorted[i].year == sorted[i + 1].year) {
          expect(sorted[i].no, lessThanOrEqualTo(sorted[i + 1].no));
        }
      }
    });
  });

  group('ProblemService 통계 (TDD)', () {
    test('countByDifficulty: {하:1, 중:2, 상:2}', () {
      final counts = svc.countByDifficulty(testProblems);
      expect(counts['하'], 1);
      expect(counts['중'], 2);
      expect(counts['상'], 2);
    });

    test('countByUnit: 수열=2, 미적분=2, 확률=1', () {
      final counts = svc.countByUnit(testProblems);
      expect(counts['수열'], 2);
      expect(counts['미적분'], 2);
      expect(counts['확률'], 1);
    });

    test('availableYears에 2000~2024 포함', () {
      expect(ProblemService.availableYears.contains(2000), isTrue);
      expect(ProblemService.availableYears.contains(2024), isTrue);
      expect(ProblemService.availableYears.length, 25);
    });
  });
}
