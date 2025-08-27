import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class ShakeScreen extends StatefulWidget {
  const ShakeScreen({super.key});

  @override
  State<ShakeScreen> createState() => _ShakeScreenState();
}

class _ShakeScreenState extends State<ShakeScreen> with TickerProviderStateMixin {
  StreamSubscription? _accelerometerSub;
  bool _shaken = false;

  double _HP = 10000.0;
  double _totalDamage = 0.0;
  List<double> _jab = [];

  // アニメーション制御用
  late AnimationController _fallController;
  late Animation<double> _fallAnimation;
  bool _isBigSwing = false;

  @override
  void initState() {
    super.initState();

    _fallController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fallAnimation = Tween<double>(begin: 0, end: 300).animate(
      CurvedAnimation(parent: _fallController, curve: Curves.easeIn),
    );

    _fallController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          double jabSum = _jab.fold(0, (a, b) => a + b);
          _HP -= jabSum + _totalDamage;
          _jab.clear();
          _isBigSwing = false;
        });
        _fallController.reset();
      }
    });

    _accelerometerSub = accelerometerEvents.listen((AccelerometerEvent event) {
      double x = event.x;
      double y = event.y;
      double z = event.z;
      double acceleration = sqrt(x * x + y * y + z * z);

      setState(() {
        if (acceleration > 20 && acceleration < 30) {
          _jab.add(acceleration);
        } else if (acceleration >= 30 && !_isBigSwing) {
          double jabSum = _jab.fold(0, (a, b) => a + b);
          _totalDamage = acceleration + jabSum;
          _isBigSwing = true;
          _fallController.forward();
        }
      });

      if (_HP <= 0 && !_shaken) {
        debugPrint("クリア！加速度 = $acceleration");
        _shaken = true;
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _fallController.dispose();
    _accelerometerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('振れ！！')),
      body: Stack(
        children: [
          // 上部に小振りの加速度リスト
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 200,
              child: ListView.builder(
                itemCount: _jab.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _fallController,
                    builder: (context, child) {
                      double offset = _isBigSwing ? _fallAnimation.value : 0;
                      return Transform.translate(
                        offset: Offset(0, offset),
                        child: Text(
                          _jab[index].toStringAsFixed(2),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // 中央にHPとダメージ表示
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HP表示
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          _HP.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 4
                              ..color = Colors.black,
                          ),
                        ),
                        Text(
                          _HP.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 50,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],                     
                  ),
                  const SizedBox(width: 4),
                    const Text(
                      "HP",
                      style: TextStyle(fontSize: 24, color: Colors.black),
                    ),                  
                ],
              ),
                const SizedBox(height: 20),

                // ダメージ表示
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const SizedBox(width: 30),
                        Text(
                          _totalDamage.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 3
                              ..color = const Color.fromARGB(255, 212, 175, 55),
                          ),
                        ),
                        Text(
                          _totalDamage.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 40,
                            color: Color.fromARGB(255, 0, 0, 255),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "damages",
                      style: TextStyle(fontSize: 24, color: Colors.black),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
