import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' ;
import 'package:jp_transliterate/jp_transliterate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class SpeechPage extends StatefulWidget {
  const SpeechPage({super.key});

  @override
  State<SpeechPage> createState() => _SpeechPageState();
}

const List<Map<String, String>> quotes = [
  {
    "quote": "成功の反対は失敗ではない。\n何もしないことだ。",
    "plain": "せいこうのはんたいはしっぱいではないなにもしないことだ",
    "by": "稲盛和夫",
  },
  {
    "quote": "今日という日は、残りの人生の最初の日である。",
    "plain": "きょうというひはのこりのじんせいのさいしょのひである",
    "by": "チャールズ・ディケンズ",
  },
  {
    "quote": "幸せだから笑うのではない。笑うから幸せなのだ。",
    "plain": "しあわせだからわらうのではないわらうからしあわせなのだ",
    "by": "ウィリアム・ジェームズ",
  },
  {
    "quote": "心が変われば行動が変わる。行動が変われば習慣が変わる。",
    "plain": "こころがかわればこうどうがかわるこうどうがかわればしゅうかんがかわる",
    "by": "ウィリアム・ジェームズ",
  },
  {
    "quote": "悩んで動けなくなるより、動いて悩め。",
    "plain": "なやんでうごけなくなるよりうごいてなやめ",
    "by": "堀江貴文",
  },
  {
    "quote": "道に迷うことは、新しい道を見つけることでもある。",
    "plain": "みちにまようことはあたらしいみちをみつけることでもある",
    "by": "坂本龍一",
  },
];

class _SpeechPageState extends State<SpeechPage> {
  late SpeechToText _speech;
  bool _isListening = false;
  String _text = "ボタンを押して話してください";
  int ranid = 0;
  String? plain;

  @override
  void initState() {
    final random = Random();
    ranid = random.nextInt(quotes.length);
    plain = quotes[ranid]["plain"];
    _speech = SpeechToText();
    super.initState();
    
  }
  @override
  void dispose() {
    _speech.stop();   
    _speech.cancel(); 
    super.dispose();
  }
  Future<void> _listen() async {
    print("aaaa");
    if (!_isListening) {
      print("bbbb");
      bool available = await _speech.initialize(
        onStatus: (status) => print("onStatus: $status"),
        onError: (error) => print("onError: $error"),
      );
      print("$available");
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: "ja_JP",
          onResult: (result) async {
            final spoken = result.recognizedWords;

            // 「漢字をひらがなに」変換
            final data = await JpTransliterate.transliterate(kanji: spoken);
            final recognizedHiragana = data.hiragana;

            setState(() {
              _text = recognizedHiragana;
            });

            if (plain != null && recognizedHiragana.contains(plain!)) {
              Navigator.pop(context);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("今日の名言",style: GoogleFonts.shipporiMinchoB1(fontSize: 30, fontWeight: FontWeight.bold),),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(quotes[ranid]["quote"] ?? "エラー",style: GoogleFonts.shipporiMinchoB1(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("by:${quotes[ranid]["by"]}"),
            const SizedBox(height: 10),
            Text(_text),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async{
                await _listen();
              },
              child: Text(_isListening ? "停止" : "話す"),
            ),
            ElevatedButton(
              onPressed: () async{
                setState(() {
                  final random = Random();
                  ranid = random.nextInt(quotes.length);
                  plain = quotes[ranid]["plain"];
                });
              },
              child: Text("チェンジ"),
            ),
          ],
        ),
      ),
    );
  }
}
