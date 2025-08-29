import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:sensors_plus/sensors_plus.dart';


class Fortune {
  final String label;
  final String message;
  final Color color;
  final double weight;
  const Fortune(this.label, this.message, this.color, this.weight);
}

class OmikujiPage extends StatefulWidget {
  const OmikujiPage({super.key});
  @override
  State<OmikujiPage> createState() => _OmikujiPageState();
}

class _OmikujiPageState extends State<OmikujiPage> {
  // ---- 固定設定 ----
  static const int requiredShakes = 5;
  static const double threshold = 15.0; // m/s^2
  static const Duration debounce = Duration(milliseconds: 400);

  // ---- 状態 ----
  StreamSubscription<UserAccelerometerEvent>? _sub;
  int _shakeCount = 0;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
  Fortune? _result;
  bool _paperDropped = false;

  static const fortunes = <Fortune>[
  Fortune(
    '大吉',
    '今日はまさに運命の追い風。新しい挑戦や決断には最高のタイミングです。自信を持って行動しましょう！',
    Colors.red,
    0.10,
  ),
  Fortune(
    '中吉',
    '継続は力なり。少しずつ積み重ねてきた努力が実を結ぶとき。焦らず、着実に進んでください。',
    Colors.orange,
    0.20,
  ),
  Fortune(
    '小吉',
    '日常の中にこそ幸せが隠れています。何気ない出来事にも目を向けて、小さな喜びを感じてみましょう。',
    Colors.amber,
    0.25,
  ),
  Fortune(
    '吉',
    '無理に前に進むよりも、今は流れに身を任せるのが吉。リラックスする時間を大切にすると運気も上昇します。',
    Colors.green,
    0.20,
  ),
  Fortune(
    '末吉',
    'まだ芽は出なくても、地中では根が育っています。今は準備と見極めのとき。機が熟すのを待ちましょう。',
    Colors.blue,
    0.15,
  ),
  Fortune(
    '凶',
    '思わぬトラブルに注意。今日は慎重に動くことが大切です。確認と安全第一を心がけましょう。',
    Colors.indigo,
    0.08,
  ),
  Fortune(
    '大凶',
    '心身ともに無理は禁物。トラブルを未然に防ぐためにも、今日は静かに過ごし、しっかり休養を取りましょう。',
    Colors.black,
    0.02,
  ),
];

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _startListening() {
    _sub?.cancel();
    _sub = userAccelerometerEvents.listen((e) {
      if (_result != null) return; // 結果表示中はカウントしない
      final magnitude = sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
      final now = DateTime.now();
      final enoughInterval = now.difference(_lastShake) > debounce;

      if (magnitude > threshold && enoughInterval) {
        _lastShake = now;
        _shakeCount++;
        HapticFeedback.mediumImpact();

        if (_shakeCount >= requiredShakes) {
          _drawFortune();
        } else {
          setState(() {}); // 進捗更新
        }
      }
    });
  }

  void _drawFortune() {
    final picked = _pickWeighted(fortunes, Random());
    setState(() {
      _result = picked;
      _paperDropped = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _paperDropped = true);
    });
    HapticFeedback.heavyImpact();
  }

  Fortune _pickWeighted(List<Fortune> items, Random rng) {
    final total = items.fold<double>(0, (s, f) => s + f.weight);
    double r = rng.nextDouble() * total;
    for (final f in items) {
      if (r < f.weight) return f;
      r -= f.weight;
    }
    return items.last;
  }

  void _resetToWaiting() {
    setState(() {
      _shakeCount = 0;
      _result = null;
      _paperDropped = false;
      _lastShake = DateTime.fromMillisecondsSinceEpoch(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWaiting = _result == null;
    return Scaffold(
      appBar: AppBar(title: const Text('今日のおみくじ')),
      body: Stack(
        children: [
          // 背景
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.red.shade50, Colors.white],
                ),
              ),
            ),
          ),
          // 花びら
          const Positioned.fill(
            child: IgnorePointer(child: SakuraField(count: 18)),
          ),
          // メイン
          Positioned.fill(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isWaiting ? _buildWaiting() : _buildResult(),
              ),
            ),
          ),
        ],
      ),
      // 結果時のみ終了（待機へ戻る）
      floatingActionButton: isWaiting
          ? null
          : FloatingActionButton.extended(
              onPressed: (){
                Navigator.pop(context);
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('終了'),
            ),
    );
  }

  Widget _buildWaiting() {
    final remaining = (requiredShakes - _shakeCount).clamp(0, requiredShakes);
    return Column(
      key: const ValueKey('waiting'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_2_rounded, size: 72, color: Colors.red.shade400),
        const SizedBox(height: 12),
        const Text('スマホを振ってください', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 8),
        Text('あと $remaining 回', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 18),
        _shakeProgress(_shakeCount, requiredShakes),
        const SizedBox(height: 18),
        Text(
          'しっかり振るとカウントされます',
          style: TextStyle(color: Colors.grey.shade700),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResult() {
    final f = _result!;
    return Column(
      key: const ValueKey('result'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.temple_buddhist, size: 22, color: Colors.red.shade400),
            const SizedBox(width: 6),
            Text(
              'おみくじ',
              style: TextStyle(fontSize: 16, color: Colors.red.shade400),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320), // コンパクト固定
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(
              begin: const Offset(0, -1.1),
              end: _paperDropped ? Offset.zero : const Offset(0, -1.1),
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, offset, child) =>
                FractionalTranslation(translation: offset, child: child),
            child: _OmikujiSlip(fortune: f),
          ),
        ),
      ],
    );
  }

  Widget _shakeProgress(int count, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i < count;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.red : Colors.grey.shade300,
            boxShadow: active
                ? [const BoxShadow(blurRadius: 4, spreadRadius: 0.5)]
                : [],
          ),
        );
      }),
    );
  }
}

/// --- おみくじの紙 ---
class _OmikujiSlip extends StatelessWidget {
  const _OmikujiSlip({required this.fortune});
  final Fortune fortune;

  @override
  Widget build(BuildContext context) {
    const borderW = 3.0;
    const radius = 10.0;
    const topPad = 8.0;
    const midGap = 6.0;
    const labelSize = 72.0;
    const msgSize = 16.0;
    const aspect = 1 / 1.8; // 少し背丈を低く

    return AspectRatio(
      aspectRatio: aspect,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.red, width: borderW),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              color: Colors.black26,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: topPad),
            _decorLine(),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  fortune.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w900,
                    color: fortune.color,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: midGap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                fortune.message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: msgSize, height: 1.35),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _decorLine() {
    const h = 3.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hanko(String text) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade700, width: 2.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.red.shade700,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

/// --- 桜の花びら ---
class SakuraField extends StatefulWidget {
  const SakuraField({super.key, this.count = 18});
  final int count;

  @override
  State<SakuraField> createState() => _SakuraFieldState();
}

class _SakuraFieldState extends State<SakuraField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _SakuraPainter(animation: _ctrl, count: widget.count),
      ),
    );
  }
}

class _PetalSpec {
  _PetalSpec(Random r) {
    x = r.nextDouble();
    size = r.nextDouble() * 7 + 7; // 7..14px
    amp = r.nextDouble() * 18 + 8; // 横揺れ 8..26
    speed = r.nextDouble() * 0.6 + 0.7; // 縦速度
    phase = r.nextDouble() * pi * 2;
    offset = r.nextDouble();
    rotSpeed = (r.nextDouble() - 0.5) * 1.0;
    tint = [
      Colors.pink.shade200.withOpacity(0.85),
      Colors.pink.shade300.withOpacity(0.8),
      Colors.pink.shade400.withOpacity(0.75),
    ][r.nextInt(3)];
  }
  late double x, size, amp, speed, phase, offset, rotSpeed;
  late Color tint;
}

class _SakuraPainter extends CustomPainter {
  _SakuraPainter({required this.animation, required this.count})
    : _petals = List.generate(count, (i) => _PetalSpec(Random(7331 * i + 29))),
      super(repaint: animation);
  final Animation<double> animation;
  final int count;
  final List<_PetalSpec> _petals;

  @override
  void paint(Canvas canvas, Size size) {
    final travel = size.height + 100.0;
    final t = animation.value;
    for (final p in _petals) {
      final v = (t * p.speed + p.offset) % 1.0;
      final y = v * travel - 50.0;
      final x =
          p.x * size.width + sin((t * p.speed + p.phase) * 2 * pi) * p.amp;
      final rot = (t * 2 * pi * p.rotSpeed) + p.phase * 0.3;
      _drawPetal(canvas, Offset(x, y), p.size, rot, p.tint);
    }
  }

  void _drawPetal(Canvas canvas, Offset c, double s, double rot, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot);
    final path = Path();
    path.moveTo(0, -0.6 * s);
    path.quadraticBezierTo(0.5 * s, -0.6 * s, 0.6 * s, 0);
    path.quadraticBezierTo(0, 0.7 * s, -0.6 * s, 0);
    path.quadraticBezierTo(-0.5 * s, -0.6 * s, 0, -0.6 * s);
    canvas.drawPath(path, paint);
    final highlight = Paint()..color = Colors.white.withOpacity(0.10);
    canvas.drawCircle(Offset(0.15 * s, -0.15 * s), 0.25 * s, highlight);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SakuraPainter oldDelegate) =>
      oldDelegate.count != count || oldDelegate.animation != animation;
}
