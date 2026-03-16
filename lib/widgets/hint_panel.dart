import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HintPanel extends StatelessWidget {
  final List<String> hints;
  final int revealed;
  final VoidCallback onReveal;

  const HintPanel({
    super.key,
    required this.hints,
    required this.revealed,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    if (hints.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text('힌트',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB45309),
                    )),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$revealed / ${hints.length}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92400E),
                    )),
              ),
            ],
          ),

          if (revealed > 0) const SizedBox(height: 12),

          // 공개된 힌트
          ...List.generate(revealed, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(right: 8, top: 1),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${i + 1}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        )),
                  ),
                ),
                Expanded(
                  child: Text(hints[i],
                      style: GoogleFonts.inter(
                        color: const Color(0xFF78350F),
                        fontSize: 13,
                        height: 1.6,
                      )),
                ),
              ],
            ),
          )),

          // 힌트 더보기 버튼
          if (revealed < hints.length) ...[
            if (revealed > 0) const SizedBox(height: 4),
            GestureDetector(
              onTap: onReveal,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  revealed == 0 ? '힌트 1 보기' : '힌트 ${revealed + 1} 보기',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFD97706),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          if (revealed == hints.length && hints.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 4),
                Text('모든 힌트를 확인했어요',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF16A34A),
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
