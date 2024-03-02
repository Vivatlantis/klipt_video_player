import 'package:klipt_video_player/application_controller.dart';
import 'package:klipt_video_player/danmaku.dart';
import 'package:klipt_video_player/danmaku_bullet_widget/bullet_setting.dart';
import 'package:klipt_video_player/danmaku_bullet_widget/reusable_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:video_player/video_player.dart';

import '../chewie.dart';

class KliptVideoView extends StatefulWidget {
  /// The URL that contains the video to be played
  /// It will support any format that is supported in chewie
  final String url;

  /// If video will start playing upon opening the page/using the widget
  /// Default to false
  final bool autoPlay;

  /// If the video will auto loop itself
  /// Default to false.
  final bool looping;

  /// Specify the aspect ratio of the given video
  final double aspectRatio;

  /// A list of button that can be added to the right of the screen
  /// when the video is in full screen mode
  /// Default to none.
  final List<Widget>? rightButtonList;

  /// The color used on progress bar
  /// Default to active: pinkAccent; background: grey
  final ChewieProgressColors? progressColors;

  /// The title of the video that will display on top of video
  final String? videoTitle;

  /// The image path to change the video progress bar icon
  /// Default icon will be an Android
  final String? progressBarIndicatorImagePath;

  /// The danmaku list to be displayed in the video.
  /// See danmaku.dart for a detailed structure of danmaku required to be passed in.
  final List<DanmakuData>? danmakuList;

  /// The primary color for bullet settings, loading circle, .etc
  /// Default to Colors.pinkAccent.
  final Color? primaryColor;

  const KliptVideoView(
    this.url, {
    Key? key,
    this.autoPlay = false,
    this.looping = false,
    this.aspectRatio = 16 / 9,
    this.rightButtonList,
    this.progressColors,
    this.videoTitle,
    this.progressBarIndicatorImagePath,
    this.danmakuList,
    this.primaryColor,
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
    List<DanmakuData>? danmakuList,
    Color? primaryColor,
  }) {
    // **IMPORTANT** Initialize dependencies
    Get.put(ApplicationController());
    Get.put(BulletController());
    return KliptVideoView(
      url,
      autoPlay: autoPlay,
      looping: looping,
      aspectRatio: aspectRatio,
      rightButtonList: rightButtonList,
      progressColors: progressColors,
      videoTitle: videoTitle,
      progressBarIndicatorImagePath: progressBarIndicatorImagePath,
      danmakuList: danmakuList,
      primaryColor: primaryColor,
    );
  }

  @override
  _KliptVideoViewState createState() => _KliptVideoViewState();
}

class _KliptVideoViewState extends State<KliptVideoView> {
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
        danmakuListIn: widget.danmakuList == null
            ? null
            : List.unmodifiable(widget.danmakuList!),
        primaryColor: widget.primaryColor,
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

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
