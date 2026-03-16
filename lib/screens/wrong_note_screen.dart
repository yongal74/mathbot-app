import 'package:flutter/material.dart';
import '../services/wrong_note_service.dart';
import '../services/problem_service.dart';
import '../models/wrong_note.dart';
import 'tree_screen.dart';

class WrongNoteScreen extends StatelessWidget {
  const WrongNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WrongNoteService(),
      builder: (context, _) {
        final notes = WrongNoteService().all;
        return Scaffold(
          backgroundColor: const Color(0xFF0D1117),
          appBar: AppBar(
            backgroundColor: const Color(0xFF161B22),
            foregroundColor: Colors.white,
            title: Text('오답노트 ${notes.length}문제',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: notes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📝', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 16),
                      Text('오답노트가 비어있어요',
                          style: TextStyle(color: Color(0xFF8B949E), fontSize: 16)),
                      SizedBox(height: 8),
                      Text('문제 풀다가 + 버튼으로 추가하세요',
                          style: TextStyle(color: Color(0xFF484F58), fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: notes.length,
                  itemBuilder: (ctx, i) => _WrongNoteTile(note: notes[i]),
                ),
        );
      },
    );
  }
}

class _WrongNoteTile extends StatelessWidget {
  final WrongNote note;
  const _WrongNoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final diffColor = note.difficulty == '상'
        ? const Color(0xFFFF7B72)
        : note.difficulty == '중'
            ? const Color(0xFFE3B341)
            : const Color(0xFF3FB950);

    return Dismissible(
      key: Key(note.problemId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withOpacity(0.2),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      onDismissed: (_) => WrongNoteService().remove(note.problemId),
      child: GestureDetector(
        onTap: () async {
          // 문제 로드 후 트리 화면으로
          final problems = await ProblemService().loadYear(note.year);
          final problem = problems.where((p) => p.id == note.problemId).firstOrNull;
          if (problem != null && context.mounted) {
            WrongNoteService().markReviewed(note.problemId);
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => TreeScreen(problem: problem)));
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: diffColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('${note.no}',
                      style: TextStyle(
                          color: diffColor, fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${note.year}학년도 ${note.no}번',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(note.unit,
                        style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12)),
                    if (note.memo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(note.memo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF79C0FF), fontSize: 11)),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (note.reviewCount > 0)
                    Text('복습 ${note.reviewCount}회',
                        style: const TextStyle(color: Color(0xFF3FB950), fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    '${note.savedAt.month}/${note.savedAt.day}',
                    style: const TextStyle(color: Color(0xFF484F58), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
