import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/claude_vision_service.dart';
import 'tree_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();
  File? _image;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 90);
    if (xfile == null) return;
    setState(() {
      _image = File(xfile.path);
      _error = null;
    });
    await _analyze();
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() => _loading = true);

    try {
      final problem = await ClaudeVisionService().analyzeImage(_image!);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TreeScreen(problem: problem)),
      );
    } catch (e) {
      setState(() => _error = '분석 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        title: const Text('문제 촬영', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 이미지 프리뷰
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: _image == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: Color(0xFF8B949E), size: 64),
                          SizedBox(height: 16),
                          Text('문제를 카메라로 찍거나\n갤러리에서 선택하세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF8B949E), fontSize: 15, height: 1.5)),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_image!, fit: BoxFit.contain),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            if (_loading) ...[
              const LinearProgressIndicator(color: Color(0xFF238636)),
              const SizedBox(height: 12),
              const Text('AI가 조건분해트리를 생성 중...',
                  style: TextStyle(color: Color(0xFF8B949E), fontSize: 14)),
              const SizedBox(height: 16),
            ],

            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              const SizedBox(height: 12),
            ],

            // 버튼
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.camera_alt_rounded,
                    label: '카메라',
                    color: const Color(0xFF238636),
                    onTap: _loading ? null : () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.photo_library_rounded,
                    label: '갤러리',
                    color: const Color(0xFF1F6FEB),
                    onTap: _loading ? null : () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFF21262D) : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: onTap == null ? const Color(0xFF30363D) : color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: onTap == null ? const Color(0xFF8B949E) : color, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: onTap == null ? const Color(0xFF8B949E) : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
