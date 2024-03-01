import 'package:chewie_with_danmaku/custom_chewie/src/video_view.dart';
import 'package:flutter/material.dart';

void main() {
  // Get.put(ApplicationController());
  // Get.put(BulletController());
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
  @override
  Widget build(BuildContext context) {
    // Get.put(ApplicationController());
    // Get.put(BulletController());
    return Scaffold(
      body: Center(
          child: VideoView.createWithDependencies(
        "https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4",
        autoPlay: true,
      )),
    );
  }
}
