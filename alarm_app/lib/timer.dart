import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
class timerPage extends StatefulWidget {
  const timerPage({super.key});

  @override
  State<timerPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<timerPage> {
  double? _heading;     //今の角度
  double? _baseHeading; //基準値
  Timer? _timer;
  int _counter = 0;
  final audioPlayer = AudioPlayer();//オーディオ

  @override
  void initState() {
    super.initState();
    FlutterCompass.events?.listen((event) {
      setState(() {
        if (_baseHeading == null && event.heading != null) {
          _baseHeading = event.heading;
        }
        _heading = event.heading;
      });
    });
  }
  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    if (_heading == null || _baseHeading == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }


    double relativeHeading = (_heading! - _baseHeading!);
    if (relativeHeading < 0) {
      relativeHeading += 360;
    }

    
    double angleInQuarter = relativeHeading % 90; 
    int seconds = (angleInQuarter/90 * 60).round();
    double rad = angleInQuarter / 180 * pi * 4 ;
    double radb = _counter/3000*pi;
    return Scaffold(
      appBar: AppBar(title: const Text("タイマー")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("あと：${(_counter/100)}",style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text("$seconds 秒",style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Stack(
              alignment: Alignment.center,
              children: [
                // 円の枠
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                ),
                // 中心点
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 3),
                  ),
                ),
                // 目盛り
                for (int i=0;i<12;i++)...[
                  Transform.rotate(
                    angle: (pi/6)*i,
                    alignment: Alignment.center,
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        width: 2,   
                        height: 50,  
                        color: Colors.black,
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        width: 2,   
                        height: 250, 
                        color: Colors.transparent,
                      ),
                    ],
                  )
                  )
                ],
                //目盛り（数字）
                for (int i=0;i<12;i++)...[
                  Transform.rotate(
                    angle: (pi/6)*i,
                    alignment: Alignment.center,
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${i*5}"),
                      Container(
                        alignment: Alignment.centerLeft,
                        width: 2,   
                        height: 350, 
                        color: Colors.transparent,
                      ),
                    ],
                  )
                  )
                ],
                // 秒針
                Transform.rotate(
                  angle: rad,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        width: 2,   // 秒針の長さ
                        height: 150,  // 秒針の太さ
                        color: Colors.red,
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        width: 2,   // 秒針の長さ
                        height: 150,  // 秒針の太さ
                        color: Colors.transparent,
                      ),
                    ],
                  )
                ),
                // タイマー秒針
                Transform.rotate(
                  angle: radb,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        width: 2,   // 秒針の長さ
                        height: 150,  // 秒針の太さ
                        color: Colors.blue,
                      ),
                      Container(
                        alignment: Alignment.centerLeft,
                        width: 2,   // 秒針の長さ
                        height: 150,  // 秒針の太さ
                        color: Colors.transparent,
                      ),
                    ],
                  )
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: (){
                    setState(() {
                      _baseHeading = _heading;
                      
                    });
                  }, 
                  child: Text("リセット")
                ),
                ElevatedButton(
                  onPressed: (){
                    if(_counter == 0){
                      setState(() {
                        _counter = seconds*100;
                      });
                      _timer = Timer.periodic(
                      
                      const Duration(milliseconds: 10),
                      
                      (Timer timer) {
                        
                        if(_counter > 0){
                          setState(() {
                            _counter--;
                          });
                        }
                        else{
                          timer.cancel();
                          audioPlayer.play(AssetSource("assets/.alarm.wav"));
                        }  
                      },
                    );
                    }
                    else{
                      _counter += seconds*100;
                    }
                    
                  }, 
                  child: Text("セット")
                ),
                ElevatedButton(onPressed: (){audioPlayer.stop();}, child: Text("ストップ")),
              ]
            ),
          ],
        ),
      ),
    );
  }
}
