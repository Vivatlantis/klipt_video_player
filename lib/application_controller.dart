import 'package:chewie_with_danmaku/src/flutter_danmaku_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'custom_chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class ApplicationController extends GetxController with WidgetsBindingObserver {
  RxBool isBulletSwitchOn = true.obs;

  void toggleBulletSwitch() {
    isBulletSwitchOn.value = !isBulletSwitchOn.value;
    update();
  }

  RxBool isVideoFullScreen = false.obs;

  late FlutterDanmakuController flutterDanmakuController;

  late VideoPlayerController videoPlayerController;
  late ChewieController chewieController;

  void setController(FlutterDanmakuController controller) {
    flutterDanmakuController = controller;
  }
}
