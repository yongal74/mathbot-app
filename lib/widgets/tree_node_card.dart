import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/problem.dart';
import '../core/math_format.dart';

/// 조건분해트리 노드 카드 — 3단계 점진적 공개
///
/// _expandState:
///   0 = 요약 (items[0] 만 표시)
///   1 = 간략 (items 전체, detail 숨김)
///   2 = 전체 (items + detail 아코디언)
class TreeNodeCard extends StatefulWidget {
  final TreeNode node;
  const TreeNodeCard({super.key, required this.node});

  @override
  State<TreeNodeCard> createState() => _TreeNodeCardState();
}

class _TreeNodeCardState extends State<TreeNodeCard>
    with SingleTickerProviderStateMixin {
  int _expandState = 0; // 0 = collapsed, 1 = brief, 2 = full

  @override
  Widget build(BuildContext context) {
    final n = widget.node;
    final style = _nodeStyle(n.type);
    final hasMultiItems = n.items.length > 1;
    final hasDetail = n.detail != null && n.detail!.isNotEmpty;
    final maxState = hasDetail ? 2 : (hasMultiItems ? 1 : 0);

    void handleTap() {
      if (maxState == 0) return;
      setState(() => _expandState = (_expandState + 1) % (maxState + 1));
    }

    // 화살표 회전: 0=아래(닫힘), 0.25=오른쪽(간략), 0.5=위(전체)
    final chevronTurns = _expandState == 0
        ? 0.0
        : _expandState == 1
            ? 0.25
            : 0.5;

    return GestureDetector(
      onTap: maxState > 0 ? handleTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(14),
          // 테두리 제거 — 배경색으로 카드 구분
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 행 ───────────────────────────
            Row(
              children: [
                Text(n.typeEmoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _label(n.type),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: style.label,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (n.type == 'derive') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: style.label.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '★ 핵심',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: style.label,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (maxState > 0) ...[
                  // 단계 인디케이터 (빈 원/채운 원)
                  if (maxState == 2) ...[
                    _StateIndicator(filled: _expandState >= 1, color: style.label),
                    const SizedBox(width: 3),
                    _StateIndicator(filled: _expandState >= 2, color: style.label),
                    const SizedBox(width: 6),
                  ],
                  AnimatedRotation(
                    turns: chevronTurns,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: style.label, size: 20),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // ── 본문: answer는 항상 전체 표시 ───
            if (n.type == 'answer')
              Text(
                n.items.map(mathToKorean).join('\n'),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: style.body,
                  letterSpacing: -0.5,
                ),
              )
            // ── 상태 0: 요약만 ──────────────────
            else if (_expandState == 0)
              Text(
                mathToKorean(n.items.first),
                style: GoogleFonts.inter(
                    fontSize: 15, height: 1.65, color: style.body),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              )
            // ── 상태 1/2: 전체 items ────────────
            else ...[
              ...n.items.asMap().entries.map((e) => Padding(
                    padding: EdgeInsets.only(
                        bottom: e.key < n.items.length - 1 ? 8 : 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n.items.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, right: 8),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: style.label.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${e.key + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: style.label,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            mathToKorean(e.value),
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                height: 1.65,
                                color: style.body),
                          ),
                        ),
                      ],
                    ),
                  )),

              // ── 상태 2: detail 아코디언 ─────────
              if (_expandState == 2 &&
                  n.detail != null &&
                  n.detail!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: style.label.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _detailPrefix(n.type),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: style.label,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mathToKorean(n.detail!),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.7,
                          color: style.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _label(String type) {
    switch (type) {
      case 'given':
        return '주어진 조건';
      case 'formula':
        return '적용 공식';
      case 'derive':
        return '유도 조건';
      case 'calculate':
        return '계산 과정';
      case 'answer':
        return '정답';
      default:
        return type;
    }
  }

  String _detailPrefix(String type) {
    switch (type) {
      case 'given':
        return '💡 이 조건의 의미';
      case 'formula':
        return '📐 공식이 성립하는 이유';
      case 'derive':
        return '🎯 수학 실력 포인트';
      case 'calculate':
        return '🔢 단계별 계산 근거';
      default:
        return '📌 상세 설명';
    }
  }

  _NodeStyle _nodeStyle(String type) {
    switch (type) {
      case 'given':
        return _NodeStyle(
          bg: const Color(0xFFDBEAFE), // 파스텔 블루
          label: const Color(0xFF1D4ED8),
          body: const Color(0xFF1E3A5F),
        );
      case 'formula':
        return _NodeStyle(
          bg: const Color(0xFFEDE9FE), // 파스텔 퍼플
          label: const Color(0xFF7C3AED),
          body: const Color(0xFF3B0764),
        );
      case 'derive':
        return _NodeStyle(
          bg: const Color(0xFFFED7AA), // 파스텔 오렌지
          label: const Color(0xFFEA580C),
          body: const Color(0xFF7C2D12),
        );
      case 'calculate':
        return _NodeStyle(
          bg: const Color(0xFFBBF7D0), // 파스텔 그린
          label: const Color(0xFF15803D),
          body: const Color(0xFF14532D),
        );
      case 'answer':
        return _NodeStyle(
          bg: const Color(0xFF8B5CF6),
          label: const Color(0xFFDDD6FE),
          body: Colors.white,
        );
      default:
        return _NodeStyle(
          bg: const Color(0xFFE5E7EB),
          label: const Color(0xFF6B7280),
          body: const Color(0xFF1A1A1A),
        );
    }
  }
}

/// 단계 인디케이터 점
class _StateIndicator extends StatelessWidget {
  final bool filled;
  final Color color;
  const _StateIndicator({required this.filled, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
      );
}

class _NodeStyle {
  final Color bg;
  final Color label;
  final Color body;
  const _NodeStyle({required this.bg, required this.label, required this.body});
}
