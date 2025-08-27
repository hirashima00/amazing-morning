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

  double _HP = 10000.0; // HP
  //double _attack = 0.0;
 // double _currentAttack = 0.0;
  double _totalDamage = 0.0;
  List <double> _jab = [];

  @override
  void initState() {
    super.initState();

    _accelerometerSub = accelerometerEvents.listen((AccelerometerEvent event) {
      double x = event.x;
      double y = event.y;
      double z = event.z;

      double acceleration = sqrt(x * x + y * y + z * z);

      setState(() {
        if (acceleration > 20 && acceleration < 30){
          _jab.add(acceleration);
        }else if (acceleration >= 30) {
          _totalDamage = 0.0;
    //     _currentAttack = acceleration;          
          double jabSum = _jab.fold(0,(a,b) => a+b);
          _totalDamage = jabSum + acceleration; 
          _HP -= _totalDamage;
    //      _attack = _totalDamage;
          _jab.clear();
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
body: Stack(
  children: [
    // 上部の小振りリスト
    Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 200, // 上部の表示エリア
        child: ListView.builder(
          itemCount: _jab.length,
          itemBuilder: (context, index) {
            return Text(
              _jab[index].toStringAsFixed(2),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            );
          },
        ),
      ),
    ),

    // 中央のまとめダメージとHP
    Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            " ${_totalDamage.toStringAsFixed(2)}ダメージ",
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 10),
          Text(
            "HP: ${_HP.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 30),
          ),
        ],
      ),
    ),
  ],
),
    );
  }
}
