import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../core/math_format.dart';

/// 수식 렌더링 위젯 — 교과서 품질
///
/// 사용법:
///   MathText('x^2 + 2x + 1')        → 기존 변환 (위첨자 등)
///   MathText(r'$x^2 + 2x + 1$')     → LaTeX 인라인 렌더링
///   MathText(r'$$\frac{1}{2}x^2$$') → LaTeX 블록 렌더링 (가운데 정렬)
///
/// 컨텐츠 데이터에서:
///   인라인: $\frac{1}{2}$, $\sqrt{x^2+1}$, $\int_a^b f(x)\,dx$
///   블록:   $$f'(x) = \lim_{h \to 0}\frac{f(x+h)-f(x)}{h}$$
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
      height: style?.height ?? 1.6,
    );

    // ── 블록 LaTeX: $$...$$ (줄 단위 가운데 정렬) ─────────────
    if (text.trim().startsWith(r'$$') && text.trim().endsWith(r'$$')) {
      final latex = text.trim().substring(2, text.trim().length - 2).trim();
      return _LatexBlock(latex: latex, style: baseStyle);
    }

    // ── 인라인 $...$ 혼재 텍스트 파싱 ────────────────────────
    final segments = _parseSegments(text);
    if (segments.length == 1 && !segments[0].isLatex) {
      // 순수 텍스트 — 기존 mathToKorean 변환
      return _PlainMathText(
        text: segments[0].content,
        style: baseStyle,
        textAlign: textAlign,
        maxLines: maxLines,
      );
    }

    // 혼재: 텍스트 + LaTeX 인라인 → Wrap으로 자연스럽게
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: segments.map((seg) {
        if (seg.isLatex) {
          return _LatexInline(latex: seg.content, style: baseStyle);
        }
        final converted = mathToKorean(seg.content);
        return _PlainMathText(
          text: converted,
          style: baseStyle,
          textAlign: textAlign,
        );
      }).toList(),
    );
  }

  List<_Segment> _parseSegments(String src) {
    final result = <_Segment>[];
    final pattern = RegExp(r'\$([^$]+)\$');
    int pos = 0;
    for (final m in pattern.allMatches(src)) {
      if (m.start > pos) {
        result.add(_Segment(src.substring(pos, m.start), false));
      }
      result.add(_Segment(m.group(1)!, true));
      pos = m.end;
    }
    if (pos < src.length) {
      result.add(_Segment(src.substring(pos), false));
    }
    return result.isEmpty ? [_Segment(src, false)] : result;
  }
}

class _Segment {
  final String content;
  final bool isLatex;
  const _Segment(this.content, this.isLatex);
}

// ── LaTeX 인라인 위젯 ────────────────────────────────────────
class _LatexInline extends StatelessWidget {
  final String latex;
  final TextStyle style;
  const _LatexInline({required this.latex, required this.style});

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 15.0;
    return Math.tex(
      latex,
      mathStyle: MathStyle.text,
      textStyle: style.copyWith(fontSize: fontSize),
      onErrorFallback: (e) => Text(
        latex,
        style: style.copyWith(
          color: Colors.red.shade400,
          fontSize: fontSize * 0.85,
        ),
      ),
    );
  }
}

// ── LaTeX 블록 위젯 ─────────────────────────────────────────
class _LatexBlock extends StatelessWidget {
  final String latex;
  final TextStyle style;
  const _LatexBlock({required this.latex, required this.style});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Math.tex(
          latex,
          mathStyle: MathStyle.display,
          textStyle: style.copyWith(
            fontSize: (style.fontSize ?? 15.0) * 1.1,
          ),
          onErrorFallback: (e) => SelectableText(
            latex,
            style: style.copyWith(
              color: Colors.red.shade400,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}

// ── 기존 Plain 수식 텍스트 (mathToKorean 변환 + 스택 분수) ─────
class _PlainMathText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;

  const _PlainMathText({
    required this.text,
    required this.style,
    this.textAlign,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final spans = _buildSpans(text, style);
    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
    );
  }

  List<InlineSpan> _buildSpans(String source, TextStyle baseStyle) {
    // 단독 분수: 1/3 → 스택 분수 위젯
    final fracRe = RegExp(
      r'(?<![A-Za-z0-9⁰¹²³⁴⁵⁶⁷⁸⁹ᵃᵇᶜᵈᵉᶠᵍʰⁱʲᵏˡᵐⁿᵒᵖʳˢᵗᵘᵛʷˣʸᶻ])(\d+)/(\d+)(?![A-Za-z0-9])',
    );
    final spans = <InlineSpan>[];
    int pos = 0;
    for (final m in fracRe.allMatches(source)) {
      if (m.start > pos) {
        spans.add(
            TextSpan(text: source.substring(pos, m.start), style: baseStyle));
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
    return spans.isEmpty
        ? [TextSpan(text: source, style: baseStyle)]
        : spans;
  }
}

/// 인라인 스택 분수: 분자 / 분모
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
    final fs = base * 0.78;
    final color = style.color ?? const Color(0xFF1A1A1A);
    final fw = style.fontWeight ?? FontWeight.normal;
    final ff = style.fontFamily;
    final lineW =
        math.max(numerator.length, denominator.length) * fs * 0.62 + 6.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(numerator,
              style: TextStyle(
                  fontSize: fs, color: color, fontWeight: fw, fontFamily: ff, height: 1.1)),
          Container(
            width: lineW,
            height: 1.2,
            color: color,
            margin: const EdgeInsets.symmetric(vertical: 1.5),
          ),
          Text(denominator,
              style: TextStyle(
                  fontSize: fs, color: color, fontWeight: fw, fontFamily: ff, height: 1.1)),
        ],
      ),
    );
  }
}
