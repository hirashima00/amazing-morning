import 'dart:io';
import 'package:alarm_app/gps.dart';
import 'package:alarm_app/toroku.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'timer.dart';
import 'camera2.dart';
//import 'shake.dart';
import 'mike.dart';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'omikuzi.dart';
import 'shaking.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init(); // 初期化必須
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark, 
        useMaterial3: true,
      ),
      home: AlarmPage(),
    );
  }
}
class AlarmInfo {
  final int id;
  final DateTime time;
  final int? stoper;
  AlarmInfo({required this.id, required this.time, this.stoper});
}
final audiopaths = [
  "alarm.mp3",
  "usagi.mp3",
];
class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}
class _AlarmPageState extends State<AlarmPage> {
  int _nextAlarmId = 1;
  List<AlarmInfo> _alarms = [];
  String audiopath = audiopaths[0];
  Future<void> _setAlarm() async {
    final now = DateTime.now();
    final picked = await Navigator.push<List>(
      context,
      MaterialPageRoute(builder: (context) => const torokuPage()),
    );
    // final picked = await showTimePicker(
    //   context: context,
    //   initialTime: selectedTime,
    // );

    if (picked == null) return;
    bool zumi = _alarms.any((alarm) => alarm.time.hour == picked[0] && alarm.time.minute == picked[1]);
    if (zumi) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("すでにその時間にアラームが設定されています")),
      );
      return; // 登録しない
    }
    DateTime alarmTime;
    if(picked[0] < now.hour || picked[0] == now.hour && picked[1] < now.minute){
      alarmTime = DateTime(
        now.year,
        now.month,
        now.day+1,
        picked[0],
        picked[1],
      );
    }
    else{
      alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked[0],
        picked[1],
      );
    }
    final id = _nextAlarmId++;
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: alarmTime,
      assetAudioPath: 'assets/$audiopath',
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: Duration(seconds: 5),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: 'アラーム',
        body: '時間になりました！',
        stopButton: '停止',
      ),
      warningNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: true,
    );

    await Alarm.set(alarmSettings: alarmSettings);
    int ran01 = picked[2];
    if(ran01 == 4){
      var rng = Random();
      ran01 = rng.nextInt(5);
    }
    setState(() {
      _alarms.add(AlarmInfo(id: id, time: alarmTime,stoper: ran01));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("アラームをセットしました")),
    );
  }

  Future<void> _stopAlarm(int alarmId) async {
    await Alarm.stop(alarmId);
    setState(() {
      _alarms.removeWhere((alarm) => alarm.id == alarmId);
    });
  }

  @override
  void initState() {
    super.initState();

    Alarm.ringStream.stream.listen((alarmSettings) async{
      final id = alarmSettings.id;
      final alarm = _alarms.firstWhere((alarm) => alarm.id == id);
      int? succses ;
      switch (alarm.stoper) {
        case 0:
          await Navigator.push(context,MaterialPageRoute(builder: (context) => const CameraPage(),fullscreenDialog: true,),);
          break;
        case 1:
          await Navigator.push(context,MaterialPageRoute(builder: (context) => const ShakeScreen(),fullscreenDialog: true,),);
          break;
        case 2:
          succses = await Navigator.push<int>(context,MaterialPageRoute(builder: (context) => const WorkingPage(),fullscreenDialog: true,),);
          if(succses != 0){
            if(succses == 1){
              await Navigator.push(context,MaterialPageRoute(builder: (context) => const CameraPage(),fullscreenDialog: true,),);
            }
            else if(succses == 2){
              await Navigator.push(context,MaterialPageRoute(builder: (context) => const SpeechPage(),fullscreenDialog: true,),);
            }
            else{
              await Navigator.push(context,MaterialPageRoute(builder: (context) => const ShakeScreen(),fullscreenDialog: true,),);
            }
          
          }
          break;
        case 3:
          await Navigator.push(context,MaterialPageRoute(builder: (context) => const SpeechPage(),fullscreenDialog: true,),);
          break;
      }
      await _stopAlarm(id);
      await Navigator.push(context,MaterialPageRoute(builder: (context) => const OmikujiPage(),fullscreenDialog: true,),);
      
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("アメージングアラーム"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: (){
              showDialog(
                context: context, 
                builder: (BuildContext context){
                  return AlertDialog(
                    title: Text("設定"),
                    content: Text("ファイル選択"),
                    actions: [
                      Container(
                        height: 100,
                        child: CupertinoPicker(
                          itemExtent: 30.0,
                          children: audiopaths.map((e) => Text(e)).toList(),
                          onSelectedItemChanged: (newValue) {
                            setState(() {
                              audiopath = audiopaths[newValue];
                            });
                          },
                        ),
                      ),  
                    ],
                  );
                }
              );
            }, // 設定ボタン押下時の処理
          ),
        ],
        ),
      body: Container(
        // 画面いっぱいに広がるように設定
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bak.png'), // 画像のパス
            fit: BoxFit.cover, // 画面いっぱいに広がり、はみ出る部分は切り取られる
          ),
        ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _alarms.length,
              itemBuilder: (context, index) {
                final alarm = _alarms[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(child: 
                      Text("${alarm.time.hour}時 ${alarm.time.minute}分",style: TextStyle(fontSize: 30),),
                      ),
                      IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _stopAlarm(alarm.id);
                        },
                    ),
                    ]
                  ),
                );
              },
            ),
          ),
          Row(
            children: [
              Card(
                margin: EdgeInsets.all(20),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const timerPage()),
                        );
                      }, 
                      child: Text("タイマー")
                    ),
                    SizedBox(width: 20,),
                    ElevatedButton(
                      onPressed: _setAlarm,
                      child: Text("アラームをセット"),
                    ),
                  ]
                )
              )
            ]
          ),
          SizedBox(height: 20),
        ],
      ),
      ),
    );
  }
}

