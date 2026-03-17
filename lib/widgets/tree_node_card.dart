import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/problem.dart';
import '../core/math_format.dart';

/// 조건분해트리 노드 카드 — 플립 카드 방식
///
/// 상태 0: 뒤집힌 상태 (뒷면 — 회색, 탭하라는 힌트)
/// 상태 1: 앞면 — 흰 카드에 컬러 왼쪽 바, items 전체 표시
/// 상태 2: 앞면 + detail 아코디언 펼침
///
/// 0 → 1 : 플립 애니메이션 (Y축 회전)
/// 1 → 2 : 아코디언 확장
/// 2 → 0 : 플립 역방향
class TreeNodeCard extends StatefulWidget {
  final TreeNode node;
  const TreeNodeCard({super.key, required this.node});

  @override
  State<TreeNodeCard> createState() => _TreeNodeCardState();
}

class _TreeNodeCardState extends State<TreeNodeCard>
    with SingleTickerProviderStateMixin {
  int _state = 0; // 0 = back, 1 = front, 2 = front+detail
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnim = CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    final n = widget.node;
    if (n.type == 'answer') return; // answer는 항상 표시

    final hasDetail = n.detail != null && n.detail!.isNotEmpty;
    final maxState = hasDetail ? 2 : 1;

    if (_state == 0) {
      _flipCtrl.forward();
      setState(() => _state = 1);
    } else if (_state == 1 && maxState == 2) {
      setState(() => _state = 2);
    } else {
      // 닫기
      _flipCtrl.reverse();
      setState(() => _state = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.node;

    // Answer 노드는 항상 앞면만 표시
    if (n.type == 'answer') {
      return _buildFront(n, true);
    }

    return GestureDetector(
      onTap: _onTap,
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (ctx, _) {
          final t = _flipAnim.value; // 0 = back, 1 = front
          if (t == 0.0) return _buildBack(n);
          if (t == 1.0) return _buildFront(n, false);

          // 플립 진행 중
          final angle = t * math.pi;
          final isBack = angle < math.pi / 2;
          final tilt = isBack ? angle : angle - math.pi;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(tilt),
            child: isBack ? _buildBack(n) : _buildFront(n, false),
          );
        },
      ),
    );
  }

  // ── 뒷면 (닫힌 상태) ───────────────────────────────
  Widget _buildBack(TreeNode n) {
    final accent = _accentColor(n.type);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFB0B0B0),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(n.typeEmoji, style: const TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _label(n.type),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          Icon(Icons.touch_app_rounded,
              color: Colors.white.withOpacity(0.5), size: 18),
        ],
      ),
    );
  }

  // ── 앞면 (열린 상태) ───────────────────────────────
  Widget _buildFront(TreeNode n, bool isAnswer) {
    final accent = _accentColor(n.type);
    final hasDetail = n.detail != null && n.detail!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 헤더 ────────────────────────────
            Row(children: [
              Text(n.typeEmoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _label(n.type),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (n.type == 'derive')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('★ 핵심',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      )),
                ),
              if (!isAnswer && hasDetail) ...[
                const SizedBox(width: 6),
                _StateIndicator(state: _state, color: accent),
              ],
              if (!isAnswer && !hasDetail && n.items.length > 1)
                const SizedBox.shrink(),
              if (!isAnswer)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: AnimatedRotation(
                    turns: _state >= 2 ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child:
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: _state >= 2 ? accent : accent.withOpacity(0.4),
                            size: 18),
                  ),
                ),
            ]),

            const SizedBox(height: 10),

            // ── 본문 ─────────────────────────────
            if (isAnswer)
              Text(
                n.items.map(mathToKorean).join('\n'),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: -0.5,
                ),
              )
            else ...[
              // 모든 items 표시 (front 상태부터 전체 표시)
              ...n.items.asMap().entries.map((e) => Padding(
                    padding: EdgeInsets.only(
                        bottom: e.key < n.items.length - 1 ? 8 : 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n.items.length > 1)
                          Container(
                            margin:
                                const EdgeInsets.only(top: 4, right: 8),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text('${e.key + 1}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  )),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            mathToKorean(e.value),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              height: 1.65,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),

              // ── detail 아코디언 (state 2) ────────
              if (_state >= 2 &&
                  n.detail != null &&
                  n.detail!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.06),
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
                          color: accent,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mathToKorean(n.detail!),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.7,
                          color: const Color(0xFF374151),
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

  Color _accentColor(String type) {
    switch (type) {
      case 'given':     return const Color(0xFF2563EB);
      case 'formula':   return const Color(0xFF7C3AED);
      case 'derive':    return const Color(0xFFEA580C);
      case 'calculate': return const Color(0xFF16A34A);
      case 'answer':    return const Color(0xFF8B5CF6);
      default:          return const Color(0xFF6B7280);
    }
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
      case 'given':     return '💡 이 조건의 의미';
      case 'formula':   return '📐 공식이 성립하는 이유';
      case 'derive':    return '🎯 수학 실력 포인트';
      case 'calculate': return '🔢 단계별 계산 근거';
      default:          return '📌 상세 설명';
    }
  }
}

/// 상세 단계 인디케이터
class _StateIndicator extends StatelessWidget {
  final int state;
  final Color color;
  const _StateIndicator({required this.state, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _Dot(filled: state >= 2, color: color),
        ],
      );
}

class _Dot extends StatelessWidget {
  final bool filled;
  final Color color;
  const _Dot({required this.filled, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
      );
}
