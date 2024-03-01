import 'package:chewie_with_danmaku/chewie_with_danmaku.dart';
import 'package:chewie_with_danmaku/custom_chewie/src/chewie_with_danmaku.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title});

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<DanmakuData> list = [
    DanmakuData(content: "a initial danmaku", time: 2000, position: 1),
    DanmakuData(content: "a fantastic danmaku", time: 2500, position: 1),
    DanmakuData(content: "a working danmaku", time: 3000, position: 1),
    DanmakuData(content: "a bottom danmaku", time: 3500, position: 2)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        /// MUST use createWithDependencies
        child: ChewieWithDanmaku.createWithDependencies(
          "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
          autoPlay: true,
          looping: true,
          aspectRatio: 16 / 9,
          rightButtonList: null,
          videoTitle: "A butterfly demo",
          danmakuList: list,
          primaryColor: Colors.pinkAccent,
        ),
      ),
    );
  }
}
