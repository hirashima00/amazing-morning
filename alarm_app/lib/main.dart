import 'dart:io';
import 'package:alarm_app/shake.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'timer.dart';
import 'camera.dart';
import 'shake.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init(); // 初期化必須
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AlarmPage(),
    );
  }
}
class AlarmInfo {
  final int id;
  final DateTime time;

  AlarmInfo({required this.id, required this.time});
}
class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}
class _AlarmPageState extends State<AlarmPage> {
  int _nextAlarmId = 1;
  List<AlarmInfo> _alarms = [];

  Future<void> _setAlarm() async {
    TimeOfDay selectedTime = TimeOfDay.now();
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (picked == null) return;
    DateTime alarmTime;
    if(picked.hour < now.hour || picked.hour == now.hour && picked.minute < now.minute){
      alarmTime = DateTime(
        now.year,
        now.month,
        now.day+1,
        picked.hour,
        picked.minute,
      );
    }
    else{
      alarmTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );
    }
    final id = _nextAlarmId++;
    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: alarmTime,
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.2,
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

    setState(() {
      _alarms.add(AlarmInfo(id: id, time: alarmTime));
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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ShakeScreen(),
          fullscreenDialog: true,
        ),
      );
      await _stopAlarm(id);
      // showDialog(
      //   context: context,
      //   builder: (context) => AlertDialog(
      //     title: Text("アラーム鳴動中"),
      //     content: Text("アラームが鳴っています"),
      //     actions: [
      //       TextButton(
      //         onPressed: () async {
      //           await _stopAlarm(id);
      //           Navigator.pop(context);
      //         },
      //         child: const Text("停止"),
      //       ),
      //     ],
      //   ),
      // );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("アラームサンプル")),
      body: Column(
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
    );
  }
}

