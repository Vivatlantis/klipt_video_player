import 'package:chewie_with_danmaku/application_controller.dart';
import 'package:chewie_with_danmaku/src/flutter_danmaku_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:video_player/video_player.dart';

import '../../danmaku_bullet/reusable_component.dart';
import '../chewie.dart';

///播放器组件
class VideoView extends StatefulWidget {
  final String? progressBarIndicatorImagePath;
  final String url;
  final bool autoPlay;
  final bool looping;
  final double aspectRatio;
  final Function(FlutterDanmakuController) onControllerInitialized;
  final List<Widget>? rightButtonList;
  final ChewieProgressColors? progressColors;
  final String? videoTitle;
  const VideoView(
    this.url, {
    Key? key,
    this.autoPlay = false,
    this.looping = false,
    this.aspectRatio = 16 / 9,
    required this.onControllerInitialized,
    this.rightButtonList,
    this.progressColors,
    this.videoTitle,
    this.progressBarIndicatorImagePath,
  }) : super(key: key);

  @override
  _VideoViewState createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  ApplicationController controller = Get.find<ApplicationController>();

  /// 进度条颜色配置
  get _progressColors => ChewieProgressColors(
      playedColor: Colors.pinkAccent,
      handleColor: Colors.pinkAccent,
      backgroundColor: Colors.grey.withOpacity(0.5),
      bufferedColor: Colors.grey);

  @override
  void initState() {
    super.initState();
    //初始化播放器设置
    controller.videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.url));
    controller.chewieController = ChewieController(
      videoPlayerController: controller.videoPlayerController,
      //fix iOS无法正常退出全屏播放问题
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
      aspectRatio: widget.aspectRatio,
      autoPlay: widget.autoPlay,
      looping: widget.looping,
      allowMuting: false,
      allowPlaybackSpeedChanging: true,
      customControls: CustomMaterialControls(
        progressBarIndicatorImagePath: widget.progressBarIndicatorImagePath,
        videoTitle: widget.videoTitle,
        rightButtonList: widget.rightButtonList,
        onControllerInitialized: widget.onControllerInitialized,
        bottomGradient: blackLinearGradient(),
        aspectRatio: widget.aspectRatio,
      ),
      materialProgressColors: widget.progressColors ?? _progressColors,
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double playerHeight = screenWidth / widget.aspectRatio;
    return Container(
      width: screenWidth,
      height: playerHeight,
      color: Colors.grey,
      child: Chewie(
        controller: controller.chewieController,
      ),
    );
  }
}
