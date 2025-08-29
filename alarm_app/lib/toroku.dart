import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
class torokuPage extends StatefulWidget {
  const torokuPage({super.key});

  @override
  State<torokuPage> createState() => _torokuPageState();
}
final stopers = [
  "写真を撮る",
  "スマホをふる",
  "歩く",
  "喋る",
  "歩く（難）",
  "ランダム",
];
class _torokuPageState extends State<torokuPage> {
  double? _heading;     //今の角度
  double? _baseHeading; //基準値
  bool mode = true; //　手入力かコンパスか
  bool horm = false; //時か分
  late DateTime now = DateTime.now();
  late int hour = now.hour;
  late int minute = now.minute;
  int stoper = 0;
  StreamSubscription<CompassEvent>? _compass;
  TimeOfDay? _selectedTime;

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  @override
  void initState() {
    super.initState();
    
    _compass = FlutterCompass.events?.listen((event) {
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
    _compass?.cancel();
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
    int seconds = (angleInQuarter/90 * (horm ? 24 : 60)).truncate();
    double rad = angleInQuarter / 180 * pi * 4 ;
    return Scaffold(
      appBar: AppBar(
        title: const Text("アラーム設定"),
        actions: [
          Row(
          children: [
            Text(mode ? "コンパス" : "手入力", style: TextStyle(fontSize: 16)),
            Switch(
              value: mode,
              onChanged: (value) {
                setState(() {
                  mode = value;
                });
              },
            ),
          ],
        ),
    const SizedBox(width: 10),
        ],
        ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("止め方を設定",style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            //止め方
            Container(
              height: 100,
              child: CupertinoPicker(
                itemExtent: 30.0,
                children: stopers.map((e) => Text(e)).toList(),
                onSelectedItemChanged: (newValue) {
                  setState(() {
                    stoper = newValue;
                  });
                },
              ),
            ),  
            if(mode)...[  
              Text(horm ?"$seconds 時$minute 分":"$hour 時$seconds 分",style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Stack(
                alignment: Alignment.center,
                children: [
                  // 円の枠
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 3),
                    ),
                  ),
                  // 中心点
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
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
                          color: Colors.grey,
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
                        Text(horm ? "$i" : "${i*5}"),
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
                      if(horm ){
                        hour = seconds;
                      }
                      else{
                        minute = seconds;
                      }
                      List<int> time = [hour,minute,stoper];
                      Navigator.pop(context, time);
                    },
                    child: Text("セット")
                  ),
                  FlutterSwitch(
                    width: 100,
                    height: 40,
                    toggleSize: 30,
                    valueFontSize: 20,
                    activeText: "時",
                    inactiveText: "分",
                    showOnOff: true,
                    value: horm,
                    onToggle: (val) {
                      setState(() {
                        if(val){
                          minute = seconds;
                        }
                        else{
                          hour = seconds;
                        }
                        horm = val;
                      });
                    },
                  ),
                ]
              ),
            ]
            else...[
              Text(
                _selectedTime != null
                    ? "${_selectedTime!.hour} 時 ${_selectedTime!.minute} 分"
                    : "まだ選択されていません",
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 30),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _pickTime,
                    child: Text("時刻入力"),
                  ),
                  ElevatedButton(
                    onPressed: (){
                      List<int> time = [_selectedTime!.hour,_selectedTime!.minute,stoper];
                      Navigator.pop(context, time);
                    },
                    child: Text("セット")
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
