import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter/painting.dart' show GradientRotation;
import 'package:camera/camera.dart';
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  // カメラ周り
  CameraController? _controller;
  bool _initializing = true;
  bool _capturing = false;
  String? _initError;

  // 表示用
  XFile? _photo;
  final _rand = Random();
  static const List<String> _compliments = [
    '✨ いい写真ですね ✨',
    '🎉 最高の一枚！',
    '💡 センスが光ってる！',
    '📸 構図が神！',
    '🌈 色味が最高！',
    '☀️ 光がすばらしい！',
    '🔥 被写体が生きてる！',
    '🎯 ピントばっちり！',
    '🎭 ドラマチック！',
    '🌟 これは映える！',
  ];
  String? _praise;

  // 褒め演出リスタート用トリガ
  int _praiseTick = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cams.first,
      );
      final ctrl = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false, // マイク権限不要
      );
      await ctrl.initialize(); // 権限確認もここで
      if (!mounted) return;
      setState(() {
        _controller = ctrl;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
        _initializing = false;
      });
    }
  }

  Future<void> _onShutter() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await ctrl.takePicture(); // ← シャッター
      await HapticFeedback.lightImpact();
      if (!mounted) return;
      // 即・表示モードへ
      setState(() {
        _photo = file;
        _praise = _compliments[_rand.nextInt(_compliments.length)];
        _praiseTick++; // ← 褒め演出をリスタート
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('撮影エラー: $e')));
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _resetToStart() {
    setState(() => _photo = null); // プレビューに戻る
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photo != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('朝だから！'),
        automaticallyImplyLeading: false
        ),
      body: Column(
        children: [
          if (hasPhoto)
            BoomPraiseBanner(
              text: _praise ?? _compliments.first,
              trigger: _praiseTick,
            ),

          Expanded(
            child: hasPhoto
                // 表示モード：写真＋ネオン枠＋右下「戻る」
                ? Stack(
                    children: [
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final maxW = constraints.maxWidth - 32; // 枠の外側余白
                            final maxH = constraints.maxHeight - 32;
                            return Center(
                              child: NeonPhotoFrame(
                                thickness: 12,
                                radius: 24,
                                glow: true,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: maxW,
                                    maxHeight: maxH,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24 - 2),
                                    child: InteractiveViewer(
                                      child: Image.file(
                                        File(_photo!.path),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.extended(
                          heroTag: 'backBtn',
                          onPressed: (){
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('戻る'),
                        ),
                      ),
                    ],
                  )
                // プレビューモード：カメラプレビュー＋中央下にシャッター
                : _buildPreviewArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_initError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('カメラ初期化エラー:\n$_initError', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _initCamera, child: const Text('再試行')),
          ],
        ),
      );
    }
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) {
      return const Center(child: Text('カメラが初期化されていません'));
    }

    return Stack(
      children: [
        // プレビュー（アスペクト比維持）
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: ctrl.value.previewSize!.height,
              height: ctrl.value.previewSize!.width,
              child: CameraPreview(ctrl),
            ),
          ),
        ),
        // 中央下のシャッターボタン
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Transform.rotate(
                //     angle: (-1*pi/6),
                //     alignment: Alignment.center,
                //     child: Column(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //     Text("とれ！",style: TextStyle(fontSize: 100),),
                //     ],
                //   )
                // ),
                SizedBox(height: 100,),
                FloatingActionButton.large(
                  heroTag: 'shutter',
                  onPressed: _capturing ? null : _onShutter,
                  child: const Icon(Icons.camera_alt),
                ),
                if (_capturing)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// ド派手バナー：BOOM出現 + キラッ + 花火絵文字
/// ─────────────────────────────────────────────────────────────
class BoomPraiseBanner extends StatefulWidget {
  const BoomPraiseBanner({
    super.key,
    required this.text,
    required this.trigger,
  });
  final String text;

  /// 値が変わると演出をリスタート（撮影ごとに ++ する）
  final int trigger;

  @override
  State<BoomPraiseBanner> createState() => _BoomPraiseBannerState();
}

class _BoomPraiseBannerState extends State<BoomPraiseBanner>
    with TickerProviderStateMixin {
  late final AnimationController _shineCtrl; // シャイン（常時ループ）
  late AnimationController _boomCtrl; // 出現＆花火（毎回リスタート）

  // 花火の粒データ
  late List<_BurstParticle> _particles;
  final _rnd = Random();

  @override
  void initState() {
    super.initState();
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _boomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _particles = _makeParticles();
  }

  @override
  void didUpdateWidget(covariant BoomPraiseBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      // 撮影のたびに演出をリセット
      _particles = _makeParticles();
      _boomCtrl.dispose();
      _boomCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..forward();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _shineCtrl.dispose();
    _boomCtrl.dispose();
    super.dispose();
  }

  List<_BurstParticle> _makeParticles() {
    const emojis = ['✨', '🎉', '💥', '🌟', '💫'];
    final list = <_BurstParticle>[];
    final n = 300; // 粒の数（増やすと更に派手）
    for (int i = 0; i < n; i++) {
      final ang = (2 * pi / n) * i + _rnd.nextDouble() * 0.3; // 少しばらつき
      final maxR = 80 + _rnd.nextDouble() * 100; // 飛距離
      final size = 16 + _rnd.nextDouble() * 12; // 文字サイズ
      final spin =
          (_rnd.nextBool() ? 1 : -1) * (0.5 + _rnd.nextDouble() * 1.2); // 回転
      list.add(
        _BurstParticle(
          angle: ang,
          maxRadius: maxR,
          emoji: emojis[_rnd.nextInt(emojis.length)],
          size: size,
          spinTurns: spin,
          startDelay: _rnd.nextDouble() * 0.2, // ばらける遅延
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).dividerColor;

    return AnimatedBuilder(
      animation: Listenable.merge([_shineCtrl, _boomCtrl]),
      builder: (context, _) {
        final tShine = _shineCtrl.value; // 0→1 ループ
        final tBoom = Curves.easeOutBack.transform(
          min(1.0, _boomCtrl.value * 1.1),
        ); // 出現
        final tFade = Curves.easeOut.transform(_boomCtrl.value); // 花火フェード

        // 背景：横流れグラデ
        final bg = LinearGradient(
          colors: const [
            Color(0xFFFE6D73),
            Color(0xFFFFD166),
            Color(0xFF06D6A0),
            Color(0xFF118AB2),
            Color(0xFFFE6D73),
          ],
          stops: const [0.00, 0.35, 0.60, 0.85, 1.00],
          begin: Alignment(-1.0 + 2.0 * tShine, 0),
          end: Alignment(1.0 + 2.0 * tShine, 0),
        );

        // 文字のキラッ
        final shimmer = LinearGradient(
          colors: const [
            Color(0xFFFFFFFF),
            Color(0xFFFFF59D),
            Color(0xFFFFFFFF),
          ],
          stops: const [0.25, 0.5, 0.75],
          begin: Alignment(-1.5 + 3.0 * tShine, 0),
          end: Alignment(1.5 + 3.0 * tShine, 0),
          transform: const GradientRotation(0.15),
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: bg,
            border: Border(bottom: BorderSide(color: divider)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 花火（絵文字）が四方に飛び散る
                  ..._particles.map((p) {
                    // 遅延→移動の進捗
                    final prog = ((tFade - p.startDelay) / (1.0 - p.startDelay))
                        .clamp(0.0, 1.0);
                    final eased = Curves.easeOut.transform(prog);
                    final dx = cos(p.angle) * p.maxRadius * eased;
                    final dy = sin(p.angle) * p.maxRadius * eased;
                    final opacity = (1.0 - prog).clamp(0.0, 1.0);

                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(dx, dy),
                        child: Transform.rotate(
                          angle: 2 * pi * p.spinTurns * prog,
                          child: Text(
                            p.emoji,
                            style: TextStyle(fontSize: p.size),
                          ),
                        ),
                      ),
                    );
                  }),

                  // 褒め言葉：BOOM拡大 + シャイン + グロウ
                  Transform.scale(
                    scale: 0.5 + 0.3 * tBoom, // 0.7→1.2
                    child: ShaderMask(
                      shaderCallback: shimmer.createShader,
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        widget.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(blurRadius: 18, color: Color(0xFFFFFFFF)),
                            Shadow(blurRadius: 36, color: Color(0x66FFFFFF)),
                            Shadow(blurRadius: 56, color: Color(0x33FFFFFF)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BurstParticle {
  _BurstParticle({
    required this.angle,
    required this.maxRadius,
    required this.emoji,
    required this.size,
    required this.spinTurns,
    required this.startDelay,
  });
  final double angle;
  final double maxRadius;
  final String emoji;
  final double size;
  final double spinTurns; // 回転量（turns）
  final double startDelay; // 0.0~0.15 くらい
}

/// ─────────────────────────────────────────────────────────────
/// 動くネオン枠（虹色が回転・発光）
/// ─────────────────────────────────────────────────────────────
class NeonPhotoFrame extends StatefulWidget {
  const NeonPhotoFrame({
    super.key,
    required this.child,
    this.thickness = 10,
    this.radius = 20,
    this.glow = true,
  });

  final Widget child;
  final double thickness;
  final double radius;
  final bool glow;

  @override
  State<NeonPhotoFrame> createState() => _NeonPhotoFrameState();
}

class _NeonPhotoFrameState extends State<NeonPhotoFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.radius;
    final t = widget.thickness;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        // 虹色が回転するスイープグラデ
        final sweep = SweepGradient(
          colors: const [
            Color(0xFFFE6D73), // coral
            Color(0xFFFFD166), // amber
            Color(0xFF06D6A0), // teal
            Color(0xFF118AB2), // blue
            Color(0xFF9B5DE5), // purple
            Color(0xFFFE6D73), // ループ
          ],
          stops: const [0.00, 0.20, 0.45, 0.70, 0.90, 1.00],
          transform: GradientRotation(2 * pi * _ctrl.value),
        );

        return Container(
          decoration: BoxDecoration(
            gradient: sweep,
            borderRadius: BorderRadius.circular(r),
            boxShadow: widget.glow
                ? const [
                    BoxShadow(
                      blurRadius: 24,
                      spreadRadius: 2,
                      color: Color(0x66FFFFFF),
                    ),
                    BoxShadow(
                      blurRadius: 48,
                      spreadRadius: 6,
                      color: Color(0x33FFFFFF),
                    ),
                  ]
                : null,
          ),
          child: Container(
            margin: EdgeInsets.all(t), // 枠の厚み分だけ内側へ
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(r - t),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
