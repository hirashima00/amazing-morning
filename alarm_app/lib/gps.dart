import 'package:alarm_app/camera2.dart';
import 'package:alarm_app/mike.dart';
import 'package:alarm_app/omikuzi.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
class WorkingPage extends StatefulWidget {
  const WorkingPage({super.key});

  @override
  State<WorkingPage> createState() => _WorkingPageState();
}

class _WorkingPageState extends State<WorkingPage> {
  Position? _startPosition;
  Position? _currentPosition;
  double _movedDistance = 0.0;
  
  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }
  @override
  void dispose() {
    
    super.dispose();
  }
  Future<void> _initLocationTracking() async {
    // 権限確認
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // 現在地を初期位置として保存
    _startPosition = await Geolocator.getCurrentPosition();
    print("初期位置：$_startPosition");

    // リアルタイムで位置を監視
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0, // すべての更新を受け取る
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
        if (_startPosition != null) {
          _movedDistance = Geolocator.distanceBetween(
            _startPosition!.latitude,
            _startPosition!.longitude,
            position.latitude,
            position.longitude,
          );
        }

        // 5m以上動いたら戻る
        if (_movedDistance >= 5) {
          Navigator.pop(context,0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_currentPosition == null) {
      // まだ位置が取れていないとき
      bodyContent = Column(
        
        mainAxisAlignment: MainAxisAlignment.center,
        children:  [
          Transform.rotate(
                    angle: (-1*pi/6),
                    alignment: Alignment.center,
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Text("走れ！",style: TextStyle(fontSize: 100),),
                ],
              )
            ),
          SizedBox(height: 100),
          Text("位置情報を取得中...\n動かないで"),
          SizedBox(height: 20),
          CircularProgressIndicator(), // クルクル追加
        ],
      );
    } else {
      // 位置が取れたとき
      bodyContent = Center(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(
                    angle: (-1*pi/6),
                    alignment: Alignment.center,
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Text("走れ！",style: TextStyle(fontSize: 100),),
                ],
              )
            ),
          SizedBox(height: 100,),
          Text("移動距離: ${_movedDistance.toStringAsFixed(2)} m"),
        ],
        )
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("移動中"),
        automaticallyImplyLeading: false
        ),
      body: Center(
        child: Column(
          children: [
            bodyContent,
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
        )
      ),
    );
  }
}
