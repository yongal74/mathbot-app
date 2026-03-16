import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/problem.dart';

/// 조건분해트리 노드 카드
/// - 기본: 노드 타입 + items[0] (요약)
/// - 탭: 전체 items + detail 상세 설명 펼침
class TreeNodeCard extends StatefulWidget {
  final TreeNode node;
  const TreeNodeCard({super.key, required this.node});

  @override
  State<TreeNodeCard> createState() => _TreeNodeCardState();
}

class _TreeNodeCardState extends State<TreeNodeCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.node;
    final style = _nodeStyle(n.type);
    final hasDetail = (n.detail != null && n.detail!.isNotEmpty) ||
        n.items.length > 1;

    return GestureDetector(
      onTap: hasDetail ? () => setState(() => _expanded = !_expanded) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: style.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: style.border,
            width: n.type == 'derive' ? 2 : 1,
          ),
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
                if (hasDetail)
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: style.label, size: 20),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── 본문: 기본은 items[0], 펼침은 전체 ─
            if (n.type == 'answer')
              Text(
                n.items.join('\n'),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: style.body,
                  letterSpacing: -0.5,
                ),
              )
            else if (!_expanded)
              Text(
                n.items.first,
                style: GoogleFonts.inter(
                  fontSize: 15, height: 1.65, color: style.body),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              )
            else ...[
              // 펼쳐진 상태: 전체 items
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
                          width: 20, height: 20,
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
                        e.value,
                        style: GoogleFonts.inter(
                          fontSize: 15, height: 1.65, color: style.body),
                      ),
                    ),
                  ],
                ),
              )),

              // detail 상세 설명
              if (n.detail != null && n.detail!.isNotEmpty) ...[
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
                        n.detail!,
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
      case 'given':     return '주어진 조건';
      case 'formula':   return '적용 공식';
      case 'derive':    return '유도 조건';
      case 'calculate': return '계산 과정';
      case 'answer':    return '정답';
      default:          return type;
    }
  }

  String _detailPrefix(String type) {
    switch (type) {
      case 'given':   return '💡 이 조건의 의미';
      case 'formula': return '📐 공식이 성립하는 이유';
      case 'derive':  return '🎯 수학 실력 포인트';
      case 'calculate': return '🔢 단계별 계산 근거';
      default:        return '📌 상세 설명';
    }
  }

  _NodeStyle _nodeStyle(String type) {
    switch (type) {
      case 'given':
        return _NodeStyle(
          bg: const Color(0xFFEFF6FF),
          border: const Color(0xFFBFDBFE),
          label: const Color(0xFF3B82F6),
          body: const Color(0xFF1E3A5F),
        );
      case 'formula':
        return _NodeStyle(
          bg: const Color(0xFFF5F3FF),
          border: const Color(0xFFDDD6FE),
          label: const Color(0xFF8B5CF6),
          body: const Color(0xFF3B0764),
        );
      case 'derive':
        return _NodeStyle(
          bg: const Color(0xFFFFF7ED),
          border: const Color(0xFFFB923C),
          label: const Color(0xFFEA580C),
          body: const Color(0xFF7C2D12),
        );
      case 'calculate':
        return _NodeStyle(
          bg: const Color(0xFFF0FDF4),
          border: const Color(0xFFBBF7D0),
          label: const Color(0xFF16A34A),
          body: const Color(0xFF14532D),
        );
      case 'answer':
        return _NodeStyle(
          bg: const Color(0xFF8B5CF6),
          border: const Color(0xFF7C3AED),
          label: const Color(0xFFDDD6FE),
          body: Colors.white,
        );
      default:
        return _NodeStyle(
          bg: const Color(0xFFF9FAFB),
          border: const Color(0xFFE5E7EB),
          label: const Color(0xFF6B7280),
          body: const Color(0xFF1A1A1A),
        );
    }
  }
}

class _NodeStyle {
  final Color bg;
  final Color border;
  final Color label;
  final Color body;
  const _NodeStyle(
      {required this.bg,
      required this.border,
      required this.label,
      required this.body});
}
