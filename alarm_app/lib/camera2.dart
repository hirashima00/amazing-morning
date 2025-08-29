import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter/painting.dart' show GradientRotation;
import 'package:camera/camera.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // camera利用前の初期化
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instant Camera Show',
      theme: ThemeData(useMaterial3: true),
      home: const CameraPage(),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  // カメラ周り
  CameraController? _controller; //カメラ本体
  bool _initializing = true;
  bool _capturing = false;
  String? _initError;

  // 表示用
  XFile? _photo; //とった写真
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

  @override //カメラを開始する関数
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    //この関数は、カメラの列挙 → 背面カメラの選択 → CameraController 生成 → initialize() 実行 → 画面状態を更新、という初期化の一連の流れを “非同期” に行います。初期化の成功/失敗に応じて UI 側（ローディング・エラー表示・プレビュー表示）を切り替える基点
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
    //シャッターボタンが押されたときの一連の処理
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
    //表示モードから撮影前のプレビューモードへ戻す
    setState(() => _photo = null); // プレビューに戻る
  }

  @override //State のライフサイクル終端処理
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  //ウィジェットツリーを組み立てる build メソッドで、
  //「写真があるかどうか」で 表示モード と プレビューモード を切り替えてる。

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photo != null;

    return Scaffold(
      appBar: AppBar(title: const Text('朝だから！')),
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
                                //虹色にまわるネオン枠
                                thickness: 12,
                                radius: 24,
                                glow: true,
                                child: ConstrainedBox(
                                  //写真の最大サイズを領域内に制限。
                                  constraints: BoxConstraints(
                                    maxWidth: maxW,
                                    maxHeight: maxH,
                                  ),
                                  child: ClipRRect(
                                    //角丸で写真を枠の内側形状に合わせて切り抜く。
                                    borderRadius: BorderRadius.circular(24 - 2),
                                    child: InteractiveViewer(
                                      //ピンチズーム／ドラッグ操作が可能に
                                      child: Image.file(
                                        //アスペクト比を壊さず収まる表示
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
                          onPressed: _resetToStart,
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

  //プレビューモードの中身を描く

  Widget _buildPreviewArea() {
    //状態ごとの分岐
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    //初期化が例外で落ちたときのエラー表示
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

    //成功時のレイアウト

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
            child: Stack(
              alignment: Alignment.center,
              children: [
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
/// 派手バナー：BOOM出現 + キラッ + 花火絵文字
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

//褒めバナーの中身

class _BoomPraiseBannerState extends State<BoomPraiseBanner>
    with TickerProviderStateMixin {
  late final AnimationController _shineCtrl; // シャイン（常時ループ）
  late AnimationController _boomCtrl; // 出現＆花火（毎回リスタート）

  // 花火の粒データ
  late List<_BurstParticle> _particles;
  final _rnd = Random();

  //起動時に シャインを常時ループ、アニメは1回再生。
  //花火の粒をランダム生成
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

  //trigger が変わったら 「撮影があった」合図。粒子を作り直し、出現アニメを リスターと。

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

  //等角度ベース + 少しのばらつきで円形に飛び散る。

  //startDelay を持たせ、一斉発射でなく僅かにばらける。

  //spinTurns は 1 周=1.0 として定義。描画で 2π * turns * 進捗 を掛けて回す。

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

  //描画

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).dividerColor;
    //ここで描画する
    return AnimatedBuilder(
      animation: Listenable.merge([_shineCtrl, _boomCtrl]),
      builder: (context, _) {
        //shine：横流れのシャイン/背景グラデの位置。
        //boom：文字のスケールに使う。easeOutBack でポップなオーバーシュート。
        //fade：粒子の進行・フェードアウトに使う。
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
                  //遅延→発射→減速→消えるを 1 粒ごとに計算。
                  //easeOut で勢いよく広がり、徐々に止まる。
                  //透明度は (1 - prog) で消えていく。
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
                  //文字自体の色をシャインのグラデで塗る（ShaderMask）。
                  //Transform.scale(scale: 0.5 + 0.3 * tBoom) で拡大出現（弾みあり）。
                  //shadows でグロウを足す。
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

//花火エフェクトの1粒を表すデータ入れ物,描画やアニメは持たず、粒ごとのパラメータだけを保持
/*angle：発射方向（ラジアン）。cos(angle),sin(angle) でXY方向を決める。
maxRadius：中心からどこまで飛ぶか（最大距離）。
emoji：粒の見た目（✨🎉💥🌟💫 など）。
size：テキストサイズ（フォントの大きさ）。
spinTurns：回転量を回転数で指定（1.0=1回転=360°、0.5=半回転）。
startDelay：この粒の発射遅延（0〜約0.2秒）。ばらけさせて一斉感を減らす*/

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
/// 動くネオン枠（虹色が回転・発光）写真（child）を“動くネオン枠”で囲むためのコンポーネント
/// child: Widget
//枠の“中身”。あなたの写真や任意のウィジェットが入る本体です（必須）。
//thickness: double = 10 枠の太さ。外枠と中身の間の“フチ幅”になります。
//radius: double = 20 角の丸み（外枠・内枠ともに角丸で揃えます）。
//glow: bool = true 発光効果のオン/オフ。true だとソフトシャドウで“にじむ光”を追加。
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

//動くネオン枠”の中身 NeonPhotoFrame に渡された child を、回転する虹色の枠と発光効果で囲う
/*SingleTickerProviderStateMixin
アニメーション用の vsync を提供（画面に出ている間だけ駆動して省電力）。

_ctrl: AnimationController
0→1 を 3 秒周期でループさせ、虹色グラデの回転角に使う。

AnimatedBuilder
_ctrl の値が変わるたびに 必要最小限の再描画を実行。*/

class _NeonPhotoFrameState extends State<NeonPhotoFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  //起動時に 3 秒ループのコントローラを生成。画面破棄時に必ず解放（リーク防止）。

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
    final r = widget.radius; //角丸
    final t = widget.thickness; //枠の太さ

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        // 虹色が回転するスイープグラデ
        //SweepGradient は中心から角度方向へ色が変わる 円形グラデ。GradientRotation に _ctrl.value（0〜1）を 2π 倍して回転させ、虹色が回って見える。
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

        //boxShadow を白で二段重ね → にじむ光を表現（glow=false でオフ）。
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

          //枠の内側
          //外側にグラデ、内側に margin=t を入れることで「色付きの帯＝枠」を作る。角丸は外枠 r に対し、内側は r - t としてきれいな同心に。
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
