import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/math_format.dart';

/// 수식을 인라인으로 올바르게 렌더링하는 위젯
///
/// - \d+/\d+ 단순 분수 → 분자/분모 세로 스택 렌더링
/// - 나머지는 mathToKorean() 변환 (^→위첨자, _→아래첨자 등)
class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;

  const MathText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
      // height가 null이면 위젯 높이 계산에 문제가 생기므로 기본값 설정
      height: style?.height ?? 1.5,
    );
    final converted = mathToKorean(text);
    final spans = _buildSpans(converted, baseStyle);

    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }

  List<InlineSpan> _buildSpans(String source, TextStyle baseStyle) {
    // 단독 분수 패턴: 앞에 영문/숫자 없고, 뒤에 영문 없는 순수 분수
    // 예: 1/3, 5/96, 1/27 → 스택 분수
    // 제외: x/3 (분자가 변수), 이미 변환된 ²⁄₃
    final fracRe = RegExp(
      r'(?<![A-Za-z0-9⁰¹²³⁴⁵⁶⁷⁸⁹ᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐⁿᵒᵖʳˢᵗᵘᵛʷˣʸᶻ])(\d+)/(\d+)(?![A-Za-z0-9])',
    );

    final spans = <InlineSpan>[];
    int pos = 0;

    for (final m in fracRe.allMatches(source)) {
      if (m.start > pos) {
        spans.add(TextSpan(text: source.substring(pos, m.start), style: baseStyle));
      }
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _InlineFraction(
          numerator: m.group(1)!,
          denominator: m.group(2)!,
          style: baseStyle,
        ),
      ));
      pos = m.end;
    }

    if (pos < source.length) {
      spans.add(TextSpan(text: source.substring(pos), style: baseStyle));
    }

    return spans.isEmpty ? [TextSpan(text: source, style: baseStyle)] : spans;
  }
}

/// 인라인 스택 분수: 분자 위 / 가로선 / 분모 아래
class _InlineFraction extends StatelessWidget {
  final String numerator;
  final String denominator;
  final TextStyle style;

  const _InlineFraction({
    required this.numerator,
    required this.denominator,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final base = style.fontSize ?? 15.0;
    final fs = base * 0.78; // 분수는 본문보다 약간 작게
    final color = style.color ?? const Color(0xFF1A1A1A);
    final fw = style.fontWeight ?? FontWeight.normal;
    final ff = style.fontFamily;

    final numLen = numerator.length;
    final denLen = denominator.length;
    final lineW = math.max(numLen, denLen) * fs * 0.62 + 6.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            numerator,
            style: TextStyle(
              fontSize: fs,
              color: color,
              fontWeight: fw,
              fontFamily: ff,
              height: 1.05,
            ),
          ),
          Container(
            width: lineW,
            height: 1.2,
            color: color,
            margin: const EdgeInsets.symmetric(vertical: 1),
          ),
          Text(
            denominator,
            style: TextStyle(
              fontSize: fs,
              color: color,
              fontWeight: fw,
              fontFamily: ff,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}
