

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class TargetWorkingPage extends StatefulWidget {
  const TargetWorkingPage({super.key});

  @override
  State<TargetWorkingPage> createState() => _TargetWorkingPageState();
}

class _TargetWorkingPageState extends State<TargetWorkingPage> {
  Position? _currentPosition;
  double? _targetLat;
  double? _targetLon;
  double _distanceToTarget = 0.0;
  bool _goalReached = false; // ゴール到達フラグ

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  Future<void> _initLocationTracking() async {
    // 権限確認
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // 現在地を初期位置として保存
    Position start = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = start;
      // ランダムターゲット生成
      _generateRandomTarget(start.latitude, start.longitude);
    });

    // リアルタイムで位置を監視
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen((Position pos) {
      if (_goalReached) return; // 一度ゴールしたら処理しない

      setState(() {
        _currentPosition = pos;
        if (_targetLat != null && _targetLon != null) {
          _distanceToTarget = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            _targetLat!,
            _targetLon!,
          );
        }

        // ゴールに着いたら処理
        if (_distanceToTarget <= 1) {
          _goalReached = true;
          _showGoalDialog();
        }
      });
    });
  }

  /// 半径5m以内のランダムな座標を生成
  void _generateRandomTarget(double lat, double lon) {
    const radius = 5.0; // 5m
    final random = Random();

    // ランダムな角度（ラジアン）
    double angle = random.nextDouble() * 2 * pi;
    // ランダムな距離（0〜5m）
    double distance = random.nextDouble() * radius;

    // 1度の緯度 ≈ 111,000m
    double deltaLat = (distance * cos(angle)) / 111000.0;
    // 1度の経度 ≈ 111,000m * cos(latitude)
    double deltaLon = (distance * sin(angle)) / (111000.0 * cos(lat * pi / 180));

    _targetLat = lat + deltaLat;
    _targetLon = lon + deltaLon;

    print("ゴール座標: $_targetLat, $_targetLon");
  }

  /// ゴールしたときのダイアログ表示
  void _showGoalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // タップで閉じない
      builder: (context) {
        return AlertDialog(
          title: const Text("ゴール！"),
          content: const Text("目的地に到着しました！"),
        );
      },
    );

    // 2秒後にダイアログを閉じて前のページに戻る
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // ダイアログを閉じる
      Navigator.pop(context,0); // 前の画面に戻る
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_currentPosition == null || _targetLat == null || _targetLon == null) {
      bodyContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text("位置情報を取得中...\n動かないで"),
          SizedBox(height: 20),
          CircularProgressIndicator(),
        ],
      );
    } else {
      bodyContent = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("現在地:"),
          Text("緯度: ${_currentPosition!.latitude.toStringAsFixed(5)}"),
          Text("経度: ${_currentPosition!.longitude.toStringAsFixed(5)}"),
          const SizedBox(height: 20),
          Text("ゴール座標:"),
          Text("緯度: ${_targetLat!.toStringAsFixed(6)}"),
          Text("経度: ${_targetLon!.toStringAsFixed(6
          )}"),
          const SizedBox(height: 20),
          Text("ゴールまでの距離: ${_distanceToTarget.toStringAsFixed(2)} m"),
          Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                
                onPressed: () {
                  final pages = [
                    {'title': 'カメラ', },
                    {'title': '音声', },
                    {'title': 'スマホをフル', },
                  ];

                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: pages.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final page = pages[index];
                            return ListTile(
                              title: Text(page['title'] as String),
                              onTap: () async{
                                Navigator.pop(context); 
                                Navigator.pop(context,index+1);
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                },
                child: const Icon(Icons.menu),
              ),
            )
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("目指せ！！")),
      body: Center(child: bodyContent),
    );
  }
}
