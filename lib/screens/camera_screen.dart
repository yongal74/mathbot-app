import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../services/claude_vision_service.dart';
import 'tree_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();
  XFile? _xfile;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(
        source: source, imageQuality: 90, maxWidth: 1600);
    if (xfile == null) return;
    setState(() {
      _xfile = xfile;
      _error = null;
    });
    await _analyze();
  }

  Future<void> _analyze() async {
    if (_xfile == null) return;
    setState(() => _loading = true);

    try {
      final bytes = await _xfile!.readAsBytes();
      final problem = await ClaudeVisionService().analyzeImageBytes(bytes);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TreeScreen(problem: problem)),
      );
    } catch (e) {
      if (mounted) setState(() => _error = '분석 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Text('문제 사진 분석',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  )),
              const SizedBox(height: 4),
              Text('수학 문제를 사진으로 찍으면 조건분해트리를 만들어드려요',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: AppColors.textSecondary)),

              const SizedBox(height: 20),

              // 이미지 프리뷰
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _xfile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_outlined,
                                  color: AppColors.primary, size: 40),
                            ),
                            const SizedBox(height: 16),
                            Text('문제 사진을 업로드하세요',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                )),
                            const SizedBox(height: 6),
                            Text('카메라 또는 갤러리에서 선택',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                          ],
                        )
                      : FutureBuilder<dynamic>(
                          future: _xfile!.readAsBytes(),
                          builder: (ctx, snap) {
                            if (!snap.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary));
                            }
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.memory(
                                snap.data!,
                                fit: BoxFit.contain,
                              ),
                            );
                          },
                        ),
                ),
              ),

              const SizedBox(height: 16),

              if (_loading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.primaryMedium,
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Text('AI가 조건분해트리를 생성 중...',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
              ],

              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_error!,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFFDC2626))),
                ),
                const SizedBox(height: 12),
              ],

              // 버튼
              Row(
                children: [
                  Expanded(
                    child: _PickButton(
                      icon: Icons.camera_alt_rounded,
                      label: '카메라',
                      color: AppColors.primary,
                      onTap: _loading
                          ? null
                          : () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickButton(
                      icon: Icons.photo_library_rounded,
                      label: '갤러리',
                      color: const Color(0xFF0284C7),
                      onTap: _loading
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                    ),
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

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _PickButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: disabled ? AppColors.surfaceHover : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: color.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(icon,
                color: disabled ? AppColors.textTertiary : color, size: 30),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: disabled ? AppColors.textTertiary : color,
                )),
          ],
        ),
      ),
    );
  }
}
