import 'package:chewie_with_danmaku/application_controller.dart';
import 'package:chewie_with_danmaku/danmaku_bullet/bullet_setting.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:video_player/video_player.dart';

import '../../danmaku_bullet/reusable_component.dart';
import '../chewie.dart';

class VideoView extends StatefulWidget {
  /// The URL that contains the video to be played
  final String url;

  /// If video will start playing upon opening the page/using the widget
  final bool autoPlay;

  /// If the video will auto loop itself
  final bool looping;

  /// Specify the aspect ratio of the given video
  final double aspectRatio;

  /// A list of button that can be added to the right of the screen
  /// when the video is in full screen mode
  final List<Widget>? rightButtonList;

  /// The color used on progress bar
  final ChewieProgressColors? progressColors;

  /// The title of the video that will display on top of video
  final String? videoTitle;

  /// The image path to change the video progress bar icon
  final String? progressBarIndicatorImagePath;

  const VideoView(
    this.url, {
    Key? key,
    this.autoPlay = false,
    this.looping = false,
    this.aspectRatio = 16 / 9,
    this.rightButtonList,
    this.progressColors,
    this.videoTitle,
    this.progressBarIndicatorImagePath,
  }) : super(key: key);

  static Widget createWithDependencies(
    String url, {
    bool autoPlay = false,
    bool looping = false,
    double aspectRatio = 16 / 9,
    List<Widget>? rightButtonList,
    ChewieProgressColors? progressColors,
    String? videoTitle,
    String? progressBarIndicatorImagePath,
  }) {
    // Initialize dependencies here
    Get.put(ApplicationController());
    Get.put(BulletController());

    // Return an instance of VideoView
    return VideoView(
      url,
      autoPlay: autoPlay,
      looping: looping,
      aspectRatio: aspectRatio,
      rightButtonList: rightButtonList,
      progressColors: progressColors,
      videoTitle: videoTitle,
      progressBarIndicatorImagePath: progressBarIndicatorImagePath,
    );
  }

  @override
  _VideoViewState createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  ApplicationController controller = Get.find<ApplicationController>();

  /// Default video progress bar color
  get _progressColors => ChewieProgressColors(
      playedColor: Colors.pinkAccent,
      handleColor: Colors.pinkAccent,
      backgroundColor: Colors.grey.withOpacity(0.5),
      bufferedColor: Colors.grey);

  @override
  void initState() {
    super.initState();
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
        onControllerInitialized:
            Get.find<ApplicationController>().setController,
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
