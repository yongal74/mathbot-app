import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

enum LegalType { privacy, terms }

class LegalScreen extends StatelessWidget {
  final LegalType type;
  const LegalScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == LegalType.privacy;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isPrivacy ? '개인정보처리방침' : '이용약관',
          style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        child: isPrivacy ? const _PrivacyPolicy() : const _TermsOfService(),
      ),
    );
  }
}

// ── 개인정보처리방침 ─────────────────────────────────────────────────────────
class _PrivacyPolicy extends StatelessWidget {
  const _PrivacyPolicy();

  @override
  Widget build(BuildContext context) {
    return _LegalBody(sections: const [
      _Section('시행일', '2025년 6월 1일'),
      _Section('개인정보처리방침 개요',
          '수능수학 조건분해트리(이하 "앱")는 이용자의 개인정보를 중요시하며, '
          '「개인정보 보호법」 및 관련 법령을 준수합니다. '
          '본 방침은 앱이 수집하는 정보, 사용 목적, 보유 기간 등을 안내합니다.'),
      _Section('수집하는 개인정보',
          '• 자동 수집: 앱 실행 기기 정보(OS 버전, 디바이스 모델), '
          '앱 사용 통계(학습 완료 문제 수, 오답 내역)\n'
          '• 결제 정보: Apple App Store 또는 Google Play를 통한 구독 결제 시 '
          '영수증 데이터(거래 ID, 구독 만료일). 카드 번호 등 결제 수단은 수집하지 않습니다.\n'
          '• 선택 수집: 사진 분석 기능 사용 시 업로드한 이미지(분석 후 즉시 삭제)'),
      _Section('개인정보 수집 및 이용 목적',
          '• 서비스 제공 및 구독 관리\n'
          '• 학습 진행 상황 저장 및 오답노트 기능 제공\n'
          '• 사진 업로드 문제 분석 (Claude AI API 전송 후 즉시 삭제)\n'
          '• 서비스 오류 개선 및 통계 분석'),
      _Section('개인정보 보유 및 이용 기간',
          '• 학습 데이터(XP, 오답노트 등): 기기 내 로컬 저장, '
          '앱 삭제 시 자동 삭제\n'
          '• 결제 영수증 검증 로그: 결제일로부터 5년 (전자상거래법 준수)\n'
          '• 사진 데이터: 분석 완료 즉시 삭제 (서버 미저장)'),
      _Section('개인정보 제3자 제공',
          '아래의 경우를 제외하고 이용자의 개인정보를 외부에 제공하지 않습니다.\n'
          '• Apple Inc. / Google LLC: 구독 결제 처리\n'
          '• Anthropic Inc.: 사진 문제 분석(Claude Vision API) — '
          '업로드 이미지만 전송, 개인 식별 정보 미포함'),
      _Section('개인정보 보호 조치',
          '• 결제 영수증 검증은 HTTPS 암호화 통신으로 처리\n'
          '• 학습 데이터는 기기 내 로컬에만 저장 (서버 전송 없음)\n'
          '• API 키 등 민감 정보는 앱 코드에 포함되지 않음'),
      _Section('이용자의 권리',
          '이용자는 다음 권리를 행사할 수 있습니다.\n'
          '• 개인정보 열람·정정·삭제 요청\n'
          '• 처리 정지 요청\n'
          '• 앱 삭제 시 기기 내 모든 데이터 삭제\n\n'
          '요청 연락처: mathbot.contact@gmail.com'),
      _Section('개인정보 보호책임자',
          '성명: 앱 운영팀\n이메일: mathbot.contact@gmail.com'),
      _Section('방침 변경',
          '본 방침 변경 시 앱 내 공지사항 또는 업데이트 내역을 통해 7일 전에 안내합니다.'),
    ]);
  }
}

// ── 이용약관 ─────────────────────────────────────────────────────────────────
class _TermsOfService extends StatelessWidget {
  const _TermsOfService();

  @override
  Widget build(BuildContext context) {
    return _LegalBody(sections: const [
      _Section('시행일', '2025년 6월 1일'),
      _Section('제1조 (목적)',
          '본 약관은 수능수학 조건분해트리 앱(이하 "서비스") 이용에 관한 '
          '운영자와 이용자 간의 권리·의무 및 책임 사항을 규정합니다.'),
      _Section('제2조 (서비스 내용)',
          '서비스는 수능 수학 기출문제 학습 및 조건분해트리 풀이 제공을 목적으로 하며, '
          '무료 플랜과 유료 구독 플랜(PRO/PREMIUM)으로 구성됩니다.\n\n'
          '• 무료: 기출 750문제 + 조건분해트리 열람\n'
          '• PRO (월 9,900원): 개념 설명, TTS, 오답노트 무제한, 사진 분석 20회/월\n'
          '• PREMIUM (월 15,900원): PRO 전체 + 사진 분석 100회/월'),
      _Section('제3조 (구독 및 결제)',
          '① 유료 구독은 Apple App Store 또는 Google Play를 통해 결제됩니다.\n'
          '② 구독은 기간 만료 24시간 전 자동으로 갱신됩니다.\n'
          '③ 자동 갱신을 취소하려면 각 스토어의 구독 관리 메뉴에서 직접 해지하십시오.\n'
          '④ 구독 취소 후에도 현재 구독 기간이 만료될 때까지 서비스는 유지됩니다.\n'
          '⑤ 환불은 각 스토어 정책에 따릅니다(Apple/Google에 직접 요청).'),
      _Section('제4조 (지적재산권)',
          '서비스 내 조건분해트리 콘텐츠, 개념 설명, UI 디자인의 저작권은 운영자에게 귀속됩니다. '
          '수능 기출문제의 저작권은 한국교육과정평가원(KICE)에 있으며, '
          '교육 목적으로 「저작권법」 제25조에 따라 활용합니다.'),
      _Section('제5조 (이용자 의무)',
          '이용자는 다음 행위를 해서는 안 됩니다.\n'
          '• 서비스 콘텐츠의 무단 복제·배포·상업적 이용\n'
          '• 앱 리버스 엔지니어링 또는 코드 추출\n'
          '• 타인의 결제 정보를 이용한 구독'),
      _Section('제6조 (서비스 변경 및 중단)',
          '운영자는 서비스 개선, 서버 점검 등의 이유로 서비스를 일시 중단할 수 있으며, '
          '유료 서비스의 중단 시 잔여 기간을 고려하여 적절한 조치를 취합니다.'),
      _Section('제7조 (면책조항)',
          '서비스는 학습 지원 목적으로 제공되며, 수능 성적 향상을 보장하지 않습니다. '
          'AI 기반 콘텐츠의 오류 가능성이 있으므로, 중요 정보는 공식 교재와 교차 확인하십시오.'),
      _Section('제8조 (준거법 및 관할)',
          '본 약관은 대한민국 법률에 따라 해석되며, '
          '분쟁 발생 시 서울중앙지방법원을 제1심 관할법원으로 합니다.'),
      _Section('문의', 'mathbot.contact@gmail.com'),
    ]);
  }
}

// ── 공통 레이아웃 ─────────────────────────────────────────────────────────────
class _Section {
  final String title;
  final String body;
  const _Section(this.title, this.body);
}

class _LegalBody extends StatelessWidget {
  final List<_Section> sections;
  const _LegalBody({required this.sections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((s) => _SectionWidget(s)).toList(),
    );
  }
}

class _SectionWidget extends StatelessWidget {
  final _Section section;
  const _SectionWidget(this.section);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.8,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
