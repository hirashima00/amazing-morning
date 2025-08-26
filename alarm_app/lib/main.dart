import 'dart:io';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';

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

class AlarmPage extends StatefulWidget {
  const AlarmPage({super.key});

  @override
  State<AlarmPage> createState() => _AlarmPageState();
}

class _AlarmPageState extends State<AlarmPage> {
  int alarmId = 0;
  List<DateTime> dateTime = [];
  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay selectedTime = TimeOfDay.now();
    final now = DateTime.now();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,    // 最初に表示する時刻を設定
    );

    if (picked != null) {
      setState(() {
        // 選択された時刻を変数に格納
        selectedTime = picked;
        dateTime.add(DateTime(
          now.year,
          now.month,
          now.day,
          selectedTime.hour,
          selectedTime.minute,
        ));
        alarmId++;
      });
    }
  }
  Future<void> _setAlarm() async {
    await _selectTime(context);
    final alarmSettings = AlarmSettings(
      id: alarmId,
      dateTime: dateTime[alarmId],
      assetAudioPath: 'assets/alarm.mp3', // pubspec.yaml に登録した音源
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.8,
        fadeDuration: const Duration(seconds: 5),
        volumeEnforced: true,
      ),
      notificationSettings: const NotificationSettings(
        title: 'アラーム',
        body: '時間になりました！',
        stopButton: '停止',
      ),
      warningNotificationOnKill: Platform.isIOS,
      androidFullScreenIntent: true,
    );

    await Alarm.set(alarmSettings: alarmSettings);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("アラームをセットしました")),
    );
  }

  Future<void> _stopAlarm() async {
    await Alarm.stop(alarmId);
  }

  @override
  void initState() {
    super.initState();
    // アラームが鳴ったときの処理を監視
    Alarm.ringStream.stream.listen((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("アラーム鳴動中"),
          content: const Text("アラームが鳴っています！"),
          actions: [
            TextButton(
              onPressed: () async {
                await _stopAlarm();
                Navigator.pop(context);
              },
              child: const Text("停止"),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("アラームサンプル")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _setAlarm,
              child: const Text("10秒後にアラームをセット"),
            ),
            ElevatedButton(
              onPressed: _stopAlarm,
              child: const Text("アラームを停止"),
            ),
            SizedBox(height: 30,),
          ],
        ),
      ),
    );
  }
}
