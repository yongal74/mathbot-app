import 'package:flutter_test/flutter_test.dart';
import 'package:mathbot_app/core/curriculum.dart';

void main() {
  group('getCurriculum 단위 테스트', () {
    test('미분 → 미적분', () => expect(getCurriculum('미분'), '미적분'));
    test('적분 → 미적분', () => expect(getCurriculum('적분'), '미적분'));
    test('접선의 방정식 → 미적분', () => expect(getCurriculum('접선의 방정식'), '미적분'));
    test('수열 → 대수', () => expect(getCurriculum('수열'), '대수'));
    test('지수·로그 → 대수', () => expect(getCurriculum('지수·로그'), '대수'));
    test('확률 → 확통', () => expect(getCurriculum('확률과통계'), '확통'));
    test('기하 → 기하', () => expect(getCurriculum('공간기하'), '기하'));
    test('집합 → 공통수학2', () => expect(getCurriculum('집합과명제'), '공통수학2'));
    test('다항식 → 공통수학1', () => expect(getCurriculum('다항식'), '공통수학1'));
    test('알 수 없는 단원 → 미적분(기본값)', () => expect(getCurriculum('unknown'), '미적분'));
  });

  group('kCurriculumOrder 순서 테스트', () {
    test('교과 순서가 올바름', () {
      expect(kCurriculumOrder.first, '공통수학1');
      expect(kCurriculumOrder.last, '기하');
      expect(kCurriculumOrder.indexOf('대수'),
          lessThan(kCurriculumOrder.indexOf('미적분')));
    });
  });
}
