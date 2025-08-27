import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' show GradientRotation; // グラデ回転
import 'package:image_picker/image_picker.dart';


class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  XFile? _photo;
  bool _busy = false;

  Future<void> _takePhoto() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final img = await _picker.pickImage(
        source: ImageSource.camera,
        // 必要なら画質・サイズ調整：
        // imageQuality: 90, maxWidth: 1920, maxHeight: 1080,
      );
      if (!mounted) return;
      setState(() => _photo = img); // キャンセル時は null のまま
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('撮影エラー: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _resetToStart() {
    setState(() => _photo = null); // 最初の画面へ
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photo != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('朝だよ起きて！'),
        automaticallyImplyLeading: false
      ),
      body: Column(
        children: [
          // 写真があるときだけ、派手めのメッセージ帯を表示
          if (hasPhoto) const FancyPraiseBanner(text: '✨ 最高に素晴らしい写真だね ✨'),

          // 写真表示領域
          Expanded(
            child: hasPhoto
                ? Stack(
                    children: [
                      // 画像本体（拡大縮小OK）
                      Positioned.fill(
                        child: InteractiveViewer(
                          child: Image.file(
                            File(_photo!.path),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // 右下オーバーレイの「戻る」ボタン
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.extended(
                          heroTag: 'backBtn',
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('戻る'),/////////////////////////////////////
                        ),
                      ),
                    ],
                  )
                : const Center(child: Text('右下のボタンで撮影 📷')),
          ),
        ],
      ),

      // 撮影前のみカメラボタンを表示（撮影後は重ならないよう非表示）
      floatingActionButton: hasPhoto
          ? null
          : FloatingActionButton.extended(
              onPressed: _busy ? null : _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: Text(_busy ? '処理中…' : '写真を撮る'),
            ),
    );
  }
}

/// 派手な上部バナー：「いい写真ですね」
class FancyPraiseBanner extends StatefulWidget {
  const FancyPraiseBanner({super.key, required this.text});
  final String text;

  @override
  State<FancyPraiseBanner> createState() => _FancyPraiseBannerState();
}

class _FancyPraiseBannerState extends State<FancyPraiseBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(); // 無限ループ
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).dividerColor;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value; // 0→1

        // 背景グラデ：横に流れていく
        final bg = LinearGradient(
          colors: const [
            Color(0xFFFE6D73), // coral
            Color(0xFFFFD166), // amber
            Color(0xFF06D6A0), // teal
            Color(0xFF118AB2), // blue
            Color(0xFFFE6D73), // coral（ループ用）
          ],
          stops: const [0.00, 0.35, 0.60, 0.85, 1.00],
          begin: Alignment(-1.0 + 2.0 * t, 0),
          end: Alignment(1.0 + 2.0 * t, 0),
        );

        // 文字のキラッとハイライト
        final shimmer = LinearGradient(
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFF59D),
            Color(0xFFFFFFFF),
          ],
          stops: const [0.25, 0.5, 0.75],
          begin: Alignment(-1.5 + 3.0 * t, 0),
          end: Alignment(1.5 + 3.0 * t, 0),
          transform: const GradientRotation(0.15),
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: bg,
            border: Border(bottom: BorderSide(color: divider)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: ShaderMask(
                shaderCallback: shimmer.createShader,
                blendMode: BlendMode.srcIn,
                child: const Text(
                  '✨ 最高に素晴らしい写真だ！ ✨',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    // 発光っぽいシャドウを重ねがけ
                    shadows: [
                      Shadow(blurRadius: 12, color: Color(0xFFFFFFFF)),
                      Shadow(blurRadius: 24, color: Color(0x66FFFFFF)),
                      Shadow(blurRadius: 36, color: Color(0x33FFFFFF)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}