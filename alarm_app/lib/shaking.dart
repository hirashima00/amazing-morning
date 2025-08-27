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

  double _HP = 1000.0; // HP
  double _attack = 0.0;
  double _currentAttack = 0.0;
  double _totalAttack = 0.0;

  @override
  void initState() {
    super.initState();

    _accelerometerSub = accelerometerEvents.listen((AccelerometerEvent event) {
      double x = event.x;
      double y = event.y;
      double z = event.z;

      double acceleration = sqrt(x * x + y * y + z * z);

      setState(() {
        if (acceleration > 30) {
          _currentAttack = acceleration;
          _HP -= _currentAttack;
          _attack = _currentAttack;
        }
        else{
          _currentAttack = 0;
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
    _accelerometerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('振れ！！')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("与えたダメージ: ${_attack.toStringAsFixed(2)}\n",
            style: const TextStyle(fontSize: 24),
            textAlign: TextAlign.center,            
            ),
            Text("残りHP: ${_HP.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
           )
          ],
        ),
      ),
    );
  }
}
