import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class ShakeScreen extends StatefulWidget {
  const ShakeScreen({super.key});

  @override
  State<ShakeScreen> createState() => _ShakeScreenState();
}

class _ShakeScreenState extends State<ShakeScreen> {
  StreamSubscription? _accelerometerSub;
  bool _shaken = false;

  double _remainingShake = 1000.0; // HP
  double _lastAcceleration = 0.0;  // 直近の加速度（表示用）

  @override
  void initState() {
    super.initState();

    _accelerometerSub = accelerometerEvents.listen((AccelerometerEvent event) {
      double x = event.x;
      double y = event.y;
      double z = event.z;

      double acceleration = sqrt(x * x + y * y + z * z);

      setState(() {
        _lastAcceleration = acceleration; // 表示用に保存
        if (acceleration > 30) {
          _remainingShake -= acceleration;
        }
      });

      if (_remainingShake <= 0 && !_shaken) {
        debugPrint("クリア！加速度 = $acceleration");
        _shaken = true;
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('振れ！！')),
      body: Center(
        child: Text(
          "与えたダメージ: ${_lastAcceleration.toStringAsFixed(2)}\n"
          "残りHP: ${_remainingShake.toStringAsFixed(2)}",
          style: const TextStyle(fontSize: 24),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
