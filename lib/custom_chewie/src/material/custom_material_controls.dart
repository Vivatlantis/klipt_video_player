import 'dart:async';
import 'dart:math';

import 'package:battery_plus/battery_plus.dart';
import 'package:chewie_with_danmaku/application_controller.dart';
import 'package:chewie_with_danmaku/src/flutter_danmaku_area.dart';
import 'package:chewie_with_danmaku/src/flutter_danmaku_bullet.dart';
import 'package:chewie_with_danmaku/src/flutter_danmaku_controller.dart';
import 'package:chewie_with_danmaku/textstyles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay/flutter_overlay.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:side_sheet/side_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';

import '../../../danmaku_bullet/bullet_color_selection.dart';
import '../../../danmaku_bullet/bullet_input_bar.dart';
import '../../../danmaku_bullet/bullet_input_box.dart';
import '../../../danmaku_bullet/bullet_setting.dart';
import '../../../danmaku_bullet/reusable_component.dart';
import '../../chewie.dart';
import '../helpers/utils.dart';
import '../notifiers/index.dart';
import '../volume_brightness_toast.dart';
import 'progress_bar.dart';

class CustomMaterialControls extends StatefulWidget {
  final String? progressBarIndicatorImagePath;
  final Widget? appBarOverlayUI;
  final Gradient? bottomGradient;
  final List<Widget>? rightButtonList;
  final Function(FlutterDanmakuController) onControllerInitialized;
  final double? aspectRatio;
  final String? videoTitle;
  const CustomMaterialControls({
    Key? key,
    required this.onControllerInitialized,
    this.appBarOverlayUI,
    this.bottomGradient,
    this.rightButtonList,
    this.aspectRatio,
    this.videoTitle,
    this.progressBarIndicatorImagePath,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return CustomMaterialControlsState();
  }
}

class CustomMaterialControlsState extends State<CustomMaterialControls>
    with SingleTickerProviderStateMixin {
  Color currentBulletSelectedColor = Colors.white;
  late FocusNode textFocusNode;
  late TextEditingController textEditingController;
  late FlutterDanmakuController flutterDanmakuController;
  List<BarrageData> jsonList = [];
  ApplicationController controller = Get.find<ApplicationController>();

  Future<void> getDanmakuListFromJSON() async {
    /// Function for your method to get danmaku from server
  }

  double get danmakuAreaHeight =>
      MediaQuery.of(context).size.width / (widget.aspectRatio ?? 16 / 9);

  Size get areaSize => Size(MediaQuery.of(context).size.width,
      min(danmakuAreaHeight, MediaQuery.of(context).size.height));
  Size get screenSize => MediaQuery.of(context).size;
  late PlayerNotifier notifier;
  late VideoPlayerValue _latestValue;
  Timer? _hideTimer;
  Timer? _initTimer;
  late var _subtitlesPosition = const Duration();
  bool _subtitleOn = false;

  Timer? _showAfterExpandCollapseTimer;

  bool lock = false;

  /// Variables for swipe to adjust volume/brightness
  bool showPlaybackSpeedMenu = false;
  bool longPress = false;
  bool _dragLeft = false;
  double? _volume;
  double? _brightness;
  late StreamController<double> _streamController;

  /// Variables for seek to function
  double _seekPos = -1.0;
  Duration _currentPos = const Duration();
  Duration _bufferPos = const Duration();

  /// Variables for bullet function
  int tickCount = 0;
  int currentTime = 0;
  bool isSeekTo = false;

  /// Variables for showing current battery status
  final Battery battery = Battery();
  StreamSubscription? batteryStateListener;
  BatteryState? batteryState;
  int batteryLevel = 0;
  late Timer batteryTimer;

  static const ProgressBarColors sliderColors = ProgressBarColors(
    cursorColor: Colors.pinkAccent,
    playedColor: Colors.pinkAccent,
    baselineColor: Color(0xFFD8D8D8),
    bufferedColor: Color(0xFF787878),
  );

  final barHeight = 48.0 * 1.5;
  final marginSize = 5.0;
  double currentPlaybackSpeed = 1.0;
  late VideoPlayerController videoPlayerController;
  ChewieController? _chewieController;

  // We know that _chewieController is set in didChangeDependencies
  ChewieController get chewieController => _chewieController!;

  @override
  void initState() {
    super.initState();
    VolumeController().listener((volume) {});
    _streamController = StreamController.broadcast();
    notifier = Provider.of<PlayerNotifier>(context, listen: false);

    textFocusNode = FocusNode();
    textEditingController = TextEditingController();
    flutterDanmakuController = FlutterDanmakuController();

    batteryStateListener =
        battery.onBatteryStateChanged.listen((BatteryState state) {
      if (batteryState == state) return;
      setState(() {
        batteryState = state;
      });
    });
    getBatteryLevel();
    batteryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      getBatteryLevel();
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      flutterDanmakuController.init(areaSize);
      print("actuall screen size = $screenSize");
      print(
          "danmaku area width = ${areaSize.width}, height =  ${areaSize.height}");
      widget.onControllerInitialized(flutterDanmakuController);
      flutterDanmakuController
          .changeShowArea(Get.find<BulletController>().displayAreaValue.value);
    });
    getDanmakuListFromJSON();
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder?.call(
            context,
            chewieController.videoPlayerController.value.errorDescription!,
          ) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 42,
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Go back", style: subtitleTextMediumWhite),
                )
              ],
            ),
          );
    }
    return buildGestureDetector(context);
  }

  GestureDetector buildGestureDetector(BuildContext context) {
    double currentValue = getCurrentVideoValue();
    return GestureDetector(
      onTap: () {
        if (notifier.hideStuff) {
          _cancelAndRestartAutoHideTimer();
        } else {
          setState(() {
            notifier.hideStuff = true;
          });
        }
      },
      onDoubleTap: !lock ? onDoubleTapFunc : null,
      onLongPress: !lock && chewieController.isPlaying ? onLongPressFunc : null,
      onLongPressUp:
          !lock && chewieController.isPlaying ? onLongPressUpFunc : null,
      onVerticalDragUpdate: !lock ? onVerticalDragUpdateFun : null,
      onVerticalDragStart: !lock ? onVerticalDragStartFun : null,
      onVerticalDragEnd: !lock ? onVerticalDragEndFun : null,
      onHorizontalDragStart: (d) =>
          !lock ? onVideoTimeChangeUpdate.call(currentValue) : null,
      onHorizontalDragUpdate: (d) {
        double deltaDx = d.delta.dx;
        if (deltaDx == 0) {
          return; // 避免某些手机会返回0.0
        }
        var dragValue = (deltaDx * 300) + currentValue;
        !lock ? onVideoTimeChangeUpdate.call(dragValue) : null;
      },
      onHorizontalDragEnd: (d) =>
          !lock ? onVideoTimeChangeEnd.call(currentValue) : null,
      child: AbsorbPointer(
        absorbing: notifier.hideStuff,
        child: Stack(children: [
          Obx(() {
            bool bulletSwitch =
                Get.find<ApplicationController>().isBulletSwitchOn.value;
            return IgnorePointer(
              ignoring: !bulletSwitch,
              child: Opacity(
                  opacity: bulletSwitch ? 1.0 : 0.0,
                  child:
                      FlutterDanmakuArea(controller: flutterDanmakuController)),
            );
          }),
          volumeBrightnessToast(),
          if (_latestValue.isBuffering)
            const Center(
              child: CircularProgressIndicator(color: Colors.pinkAccent),
            )
          else
            controller.isVideoFullScreen.value
                ? WillPopScope(
                    onWillPop: () {
                      return Future.value(true);
                    },
                    child: Container(color: Colors.transparent))
                : Container(
                    color: Colors.transparent,
                  ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              if (_subtitleOn)
                Transform.translate(
                  offset:
                      Offset(0.0, notifier.hideStuff ? barHeight * 0.8 : 0.0),
                  child: _buildSubtitles(context, chewieController.subtitle!),
                ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: buildLongPressSpeedToast(),
          ),
          Align(
            alignment: Alignment.center,
            child: buildDragProgressTimeToast(),
          ),
          AnimatedOpacity(
            opacity: notifier.hideStuff ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            child: buildPanel(context),
          ),
          if (chewieController.videoPlayerController.value.isCompleted &&
              !notifier.hideStuff)
            GestureDetector(
              onTap: () {
                chewieController.videoPlayerController.play();
              },
              child: Center(
                child: Container(
                  height: 60,
                  width: 120,
                  color: Colors.black45,
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Replay", style: subtitleTextMediumWhite),
                      SizedBox(width: 4),
                      Icon(Icons.replay, color: Colors.white)
                    ],
                  ),
                ),
              ),
            )
        ]),
      ),
    );
  }

  Widget buildPanel(BuildContext context) {
    bool fullScreen = chewieController.isFullScreen;
    Widget leftWidget = Container();
    Widget rightWidget = Container();

    if (fullScreen) {
      rightWidget = SingleChildScrollView(
        child: Padding(
          padding:
              const EdgeInsets.only(left: 10, right: 25, top: 8, bottom: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Column(
                children: widget.rightButtonList ?? [],
              ),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      );
      leftWidget = Padding(
        padding: const EdgeInsets.only(left: 32, right: 10, top: 0, bottom: 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              onTap: () {
                setState(() {
                  lock = !lock;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Visibility(
                  visible: lock,
                  replacement: const Icon(Icons.lock_open, color: Colors.white),
                  child: const Icon(Icons.lock, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!lock) videoAppBarOverlay(),
        // 中间按钮
        Expanded(
          child: Stack(
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: leftWidget,
              ),
              // 字幕开关
              // Positioned(
              //   right: 170,
              //   bottom: 0,
              //   child: Visibility(
              //     visible: !hideCaption,
              //     child: Container(
              //       decoration: BoxDecoration(
              //         color: Colors.black45,
              //         borderRadius: BorderRadius.circular(10),
              //       ),
              //       child: Padding(
              //         padding: const EdgeInsets.all(10),
              //         child: Column(
              //           children: buildCaptionListWidget(),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),

              if (!lock)
                Align(
                  alignment: Alignment.centerRight,
                  child: rightWidget,
                ),
            ],
          ),
        ),
        if (!lock) _buildBottomBar(context),
      ],
    );
  }

  Widget volumeBrightnessToast() {
    var volume = _volume;
    var brightness = _brightness;
    if (volume != null || brightness != null) {
      Widget toast = volume == null
          ? defaultFBrightnessToast(brightness!, _streamController.stream)
          : defaultFVolumeToast(volume, _streamController.stream);
      return IgnorePointer(
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 500),
          child: toast,
        ),
      );
    }
    return Container();
  }

  Widget buildDragProgressTimeToast() {
    final duration = _latestValue.duration;
    return Offstage(
      offstage: _seekPos == -1,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(0, 0, 0, .7),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            "${_durationToString(
              Duration(milliseconds: _seekPos.toInt()),
            )} / ${_durationToString(duration)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }

  /// Helper function that may be moved out
  String _durationToString(Duration duration) {
    if (duration.inMilliseconds < 0) return "-: negtive";
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    int inHours = duration.inHours;
    return inHours > 0
        ? "$inHours:$twoDigitMinutes:$twoDigitSeconds"
        : "$twoDigitMinutes:$twoDigitSeconds";
  }

  /// Change back to original speed
  void onLongPressUpFunc() {
    setState(() {
      chewieController.videoPlayerController
          .setPlaybackSpeed(currentPlaybackSpeed);
      flutterDanmakuController.changeRate(currentPlaybackSpeed);
      longPress = false;
    });
  }

  /// Change to double speed
  void onLongPressFunc() {
    if (chewieController.isPlaying) {
      setState(() {
        notifier.hideStuff = true;
        longPress = true;
        chewieController.videoPlayerController.setPlaybackSpeed(2.0);
        flutterDanmakuController.changeRate(2.0);
      });
    }
  }

  /// 获取视频当前时间, 如拖动快进时间则显示快进的时间
  double getCurrentVideoValue() {
    double duration = _latestValue.duration.inMilliseconds.toDouble();
    double currentValue;
    if (_seekPos > 0) {
      currentValue = _seekPos;
    } else {
      currentValue = _currentPos.inMilliseconds.toDouble();
    }
    currentValue = min(currentValue, duration);
    currentValue = max(currentValue, 0);
    return currentValue;
  }

  /// 快进视频时间
  void onVideoTimeChangeUpdate(double value) {
    if (_latestValue.duration.inMilliseconds < 0 ||
        value < 0 ||
        value > _latestValue.duration.inMilliseconds) {
      return;
    }
    _startAutoHideTimer();
    setState(() {
      _seekPos = value;
    });
  }

  /// 快进视频松手开始跳时间
  void onVideoTimeChangeEnd(double value) async {
    var time = _seekPos.toInt();
    currentTime = time ~/ 1000;
    print("currentTimeUpdatedTo: $time");
    _currentPos = Duration(milliseconds: time);
    videoPlayerController.seekTo(_currentPos).then((value) async {
      flutterDanmakuController.clearScreen();

      /// load your new danmaku here

      isSeekTo = true;
    });
    setState(() {
      _seekPos = -1;
    });
  }

  @override
  void dispose() {
    _dispose();
    batteryTimer.cancel();
    batteryStateListener?.cancel();
    _streamController.close();
    VolumeController().removeListener();
    textFocusNode.dispose();
    flutterDanmakuController.dispose();
    super.dispose();
  }

  void _dispose() {
    videoPlayerController.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final oldController = _chewieController;
    _chewieController = ChewieController.of(context);
    videoPlayerController = chewieController.videoPlayerController;

    if (oldController != chewieController) {
      _dispose();
      _initialize();
    }
    super.didChangeDependencies();
  }

  /// double tap to play/pause
  onDoubleTapFunc() {
    _playPause();
  }

  Widget buildLongPressSpeedToast() {
    return Offstage(
      offstage: !longPress,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 0, 0, .2),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Text(
          "Playing in 2x speed",
          style: TextStyle(
            color: Color.fromRGBO(255, 255, 255, .8),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  /// vertical drag to adjust volume/brightness
  void onVerticalDragStartFun(DragStartDetails d) {
    // 唤起菜单栏防止误触
    if (d.localPosition.dy > 40 && d.localPosition.dy < panelHeight() - 40) {
      if (d.localPosition.dx > panelWidth() / 2) {
        // right, volume
        _dragLeft = false;
        VolumeController().getVolume().then((value) {
          setState(() {
            _volume = value;
          });
        });
      } else {
        // left, brightness
        _dragLeft = true;
        ScreenBrightness().current.then((value) {
          setState(() {
            _brightness = value;
            _streamController.add(value);
          });
        });
      }
    }
  }

  void onVerticalDragUpdateFun(DragUpdateDetails d) {
    double delta;
    if (chewieController.isFullScreen) {
      delta = d.primaryDelta! / panelHeight();
    } else {
      delta = d.primaryDelta! * 2 / panelHeight();
    }
    delta = -delta.clamp(-1.0, 1.0);
    if (_dragLeft == false) {
      var volume = _volume;
      if (volume != null) {
        volume += delta;
        volume = volume.clamp(0.0, 1.0);
        _volume = volume;
        VolumeController().showSystemUI = false;
        VolumeController().setVolume(volume);
        VolumeController().showSystemUI = false;
        setState(() {
          _streamController.add(volume!);
        });
      }
    } else if (_dragLeft == true) {
      var brightness = _brightness;
      if (brightness != null) {
        brightness += delta;
        brightness = brightness.clamp(0.0, 1.0);
        _brightness = brightness;
        ScreenBrightness().setScreenBrightness(brightness);
        setState(() {
          _streamController.add(brightness!);
        });
      }
    }
  }

  void onVerticalDragEndFun(DragEndDetails e) {
    setState(() {
      _volume = null;
      _brightness = null;
    });
  }

  double panelWidth() {
    return MediaQuery.of(context).size.width;
  }

  double panelHeight() {
    return MediaQuery.of(context).size.height;
  }

  /// 字幕组件，暂时没有用
  Widget _buildSubtitles(BuildContext context, Subtitles subtitles) {
    if (!_subtitleOn) {
      return Container();
    }
    final currentSubtitle = subtitles.getByPosition(_subtitlesPosition);
    if (currentSubtitle.isEmpty) {
      return Container();
    }

    if (chewieController.subtitleBuilder != null) {
      return chewieController.subtitleBuilder!(
        context,
        currentSubtitle.first!.text,
      );
    }
    return Padding(
      padding: EdgeInsets.all(marginSize),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0x96000000),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          currentSubtitle.first!.text,
          style: subtitleTextRegular,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 底部控制栏，分竖屏和横屏（全屏）播放两种
  AnimatedOpacity _buildBottomBar(
    BuildContext context,
  ) {
    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height:
            chewieController.isFullScreen ? barHeight * 1.4 : barHeight / 1.5,
        decoration: BoxDecoration(gradient: widget.bottomGradient),
        child: chewieController.isFullScreen && _latestValue.aspectRatio > 1
            ? buildBottomBarFullScreen()
            : buildBottomBarHorizontal(),
      ),
    );
  }

  /// 竖屏时显示的底部控制栏，包含播放按钮、进度条和时间、全屏按钮
  Row buildBottomBarHorizontal() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        _buildPlayPauseButton(videoPlayerController, false),
        _buildProgressBar(),
        _buildDurationAndPosition(),
        if (chewieController.allowFullScreen) _buildExpandButton(false)
      ],
    );
  }

  /// 横屏（全屏）时显示的底部控制栏，将进度条和时间上移，
  /// 在下方增加了弹幕开关、弹幕输入框、弹幕设定按钮
  buildBottomBarFullScreen() {
    return Container(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildProgressBar(),
                _buildDurationAndPosition(),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                _buildPlayPauseButton(videoPlayerController, true),
                buildBulletSwitch(true, toggleBulletSwitch),
                _buildBulletSettingButton(),
                _buildBulletInput(),
                _buildPlaybackSpeedChangeButton(),
                _buildExpandButton(true)
              ],
            ),
          ),
        ],
      ),
    );
  }

  void toggleBulletSwitch() {
    Get.find<ApplicationController>().toggleBulletSwitch();
  }

  /// 暂停和播放按钮
  GestureDetector _buildPlayPauseButton(
      VideoPlayerController controller, bool isFullScreen) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.only(left: 12),
        child: Icon(
          controller.value.isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          color: Colors.white,
          size: isFullScreen ? 40 : 32,
        ),
      ),
    );
  }

  /// 弹幕设定按钮
  GestureDetector _buildBulletSettingButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          notifier.hideStuff = true;
        });
        SideSheet.right(
            body: BulletSetting(
                flutterDanmakuController: flutterDanmakuController),
            sheetColor: Colors.transparent,
            width: MediaQuery.of(context).size.width * 0.45,
            context: context);
      },
      child: Container(
          height: barHeight,
          color: Colors.transparent,
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: Image.asset(
            'assets/bullet_setting_white.png',
            width: 30,
            height: 30,
            package: 'chewie_with_danmaku',
          )),
    );
  }

  /// 弹幕输入框
  _buildBulletInput() {
    bool needToResume = false;
    return Expanded(child: BulletInputBar(
      onTapFunction: () {
        if (chewieController.isPlaying) {
          videoPlayerController.pause();
          flutterDanmakuController.pause();
          needToResume = true;
        }
        HiOverlay.show(
          context,
          child: BulletInput(
            currentSelectedColor: currentBulletSelectedColor,
            isFullScreen: chewieController.isFullScreen,
            onClickToClose: (color) {
              setState(() {
                currentBulletSelectedColor = color;
              });
              if (needToResume) {
                chewieController.videoPlayerController.play();
                flutterDanmakuController.play();
              }
            },
            onBulletSubmit: (text, color, isBottomBullet) {
              setState(() {
                currentBulletSelectedColor = color;
              });
              if (needToResume) {
                chewieController.videoPlayerController.play();
                flutterDanmakuController.play();
              }
              String bulletToBeSent = text.trim();
              sendBulletWhenPlayable(bulletToBeSent, color, isBottomBullet);
            },
            editingController: textEditingController,
          ),
        );
      },
    ));
  }

  /// When video is paused, the bullet will not be sent
  Future<void> sendBulletWhenPlayable(
      String bulletToBeSent, Color color, bool isBottomBullet) async {
    if (flutterDanmakuController.isPause) {
      // Wait for a short duration before checking again
      await Future.delayed(const Duration(milliseconds: 100));
      return sendBulletWhenPlayable(bulletToBeSent, color, isBottomBullet);
    }

    if (bulletToBeSent != "") {
      /// Add a function to send your bullet to serverside

      /// Display the bullet you just send on screen
      flutterDanmakuController.addDanmaku(
        bulletToBeSent,
        color: color,
        position: isBottomBullet
            ? FlutterDanmakuBulletPosition.bottom
            : FlutterDanmakuBulletPosition.any,
        bulletType: isBottomBullet
            ? FlutterDanmakuBulletType.fixed
            : FlutterDanmakuBulletType.scroll,
        builder: (Text textWidget) {
          return Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.red)),
            child: textWidget,
          );
        },
      );
      textEditingController.clear();
    }
  }

  /// 视频倍速调整按钮
  _buildPlaybackSpeedChangeButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          notifier.hideStuff = true;
        });

        SideSheet.right(
            body: _buildPlaybackSpeedMenu(),
            width: 180,
            context: context,
            sheetColor: Colors.transparent);
      },
      child: Container(
          alignment: Alignment.center,
          height: barHeight,
          color: Colors.transparent,
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: Text('$currentPlaybackSpeed' 'X',
              style: subtitleTextRegularWhite)),
    );
  }

  /// 视频倍速调整菜单
  _buildPlaybackSpeedMenu() {
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.only(top: 60, bottom: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          setSpeed(2.0),
          setSpeed(1.5),
          setSpeed(1.0),
          setSpeed(0.75),
          setSpeed(0.5),
          setSpeed(0.25),
        ],
      ),
    );
  }

  /// 设置改变视频倍速
  GestureDetector setSpeed(double speed) {
    return GestureDetector(
      onTap: () {
        currentPlaybackSpeed = speed;
        setState(() {
          chewieController.videoPlayerController.setPlaybackSpeed(speed);
          flutterDanmakuController.changeRate(speed);
        });
        Fluttertoast.showToast(msg: '$speed' 'X', gravity: ToastGravity.CENTER);
      },
      child: Text('$speed' 'X', style: bodyTextRegularWhite),
    );
  }

  /// 进入/退出全屏按钮
  GestureDetector _buildExpandButton(bool isFullScreen) {
    return GestureDetector(
      onTap: onExpandCollapse,
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        // opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: barHeight + (chewieController.isFullScreen ? 15.0 : 0),
          margin: const EdgeInsets.only(right: 12.0),
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(
              chewieController.isFullScreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
              color: Colors.white,
              size: isFullScreen ? 35 : 30,
            ),
          ),
        ),
      ),
    );
  }

  /// 用文字显示视频时间进度 （00:01 / 00:10）
  Widget _buildDurationAndPosition() {
    final position = _latestValue.position;
    final duration = _latestValue.duration;

    return Container(
      padding: EdgeInsets.only(right: chewieController.isFullScreen ? 8 : 0),
      child: Text('${formatDuration(position)} / ${formatDuration(duration)}',
          style: bodyTextRegularWhite),
    );
  }

  void _cancelAndRestartAutoHideTimer() {
    _hideTimer?.cancel();
    _startAutoHideTimer();

    setState(() {
      notifier.hideStuff = false;
    });
  }

  Future<void> _initialize() async {
    _subtitleOn = chewieController.subtitle?.isNotEmpty ?? false;
    videoPlayerController.addListener(_updateState);

    _updateState();

    if (videoPlayerController.value.isPlaying || chewieController.autoPlay) {
      _startAutoHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          notifier.hideStuff = false;
        });
      });
    }
  }

  /// enter/exit full screen
  void onExpandCollapse() {
    Size size = chewieController.videoPlayerController.value.size;
    if (size.width == 0.0) {
      print('_onExpandCollapse:videoPlayerController.value.size is null.');
      return;
    }
    setState(() {
      notifier.hideStuff = true;
      chewieController.toggleFullScreen();
      controller.isVideoFullScreen.value = !controller.isVideoFullScreen.value;
      Future.delayed(const Duration(milliseconds: 500), () {
        flutterDanmakuController.init(areaSize);
        print("new areasize = $areaSize");
      });
      _showAfterExpandCollapseTimer =
          Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartAutoHideTimer();
        });
      });
    });
  }

  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (videoPlayerController.value.isPlaying) {
        notifier.hideStuff = false;
        _hideTimer?.cancel();
        videoPlayerController.pause();
        flutterDanmakuController.pause();
      } else {
        _cancelAndRestartAutoHideTimer();

        if (!videoPlayerController.value.isInitialized) {
          videoPlayerController.initialize().then((_) {
            videoPlayerController.play();
            flutterDanmakuController.play();
          });
        } else {
          if (isFinished) {
            videoPlayerController.seekTo(const Duration());
          }
          videoPlayerController.play();
          flutterDanmakuController.play();
        }
      }
    });
  }

  /// 设置过几秒后自动将界面UI隐藏
  void _startAutoHideTimer() {
    if (!chewieController.isPlaying) return;
    _hideTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        notifier.hideStuff = true;
      });
    });
  }

  void hidePanel() {
    setState(() {
      notifier.hideStuff = true;
    });
  }

  void _updateState() async {
    if (videoPlayerController.value.isCompleted) {
      notifier.hideStuff = false;
    }
    if (!mounted) return;

    /// Load your danmaku data in advance here.
    setState(() {
      _latestValue = videoPlayerController.value;
      _currentPos = _latestValue.position;

      _subtitlesPosition = videoPlayerController.value.position;
      if (!_latestValue.isInitialized) {
        return;
      }
      if (_latestValue.isPlaying && flutterDanmakuController.isPause) {
        flutterDanmakuController.play();
      }

      /// Add danmaku to display
      currentTime = _currentPos.inSeconds.toInt();
      for (int i = 0; i < jsonList.length; i++) {
        final double danmakuTime = jsonList.elementAt(i).time! / 1000;
        String content = jsonList.elementAt(i).content!;
        double timeDifference = danmakuTime - currentTime - 1;
        if (danmakuTime < 1.2 || timeDifference >= 0 && timeDifference <= 1) {
          int offsetMS = -(timeDifference * 1000).toInt();
          flutterDanmakuController.addDanmaku(content,
              color:
                  stringToColor(jsonList.elementAt(i).color ?? "(0xFFFFFFFF)"),
              offsetMS: offsetMS,
              position: jsonList.elementAt(i).position! == 2
                  ? FlutterDanmakuBulletPosition.bottom
                  : FlutterDanmakuBulletPosition.any,
              bulletType: jsonList.elementAt(i).position! == 2
                  ? FlutterDanmakuBulletType.fixed
                  : FlutterDanmakuBulletType.scroll);
          jsonList.removeAt(i);
          i--;
        }
      }
    });
  }

  double durationToDouble(Duration d) {
    return d.inMilliseconds.toDouble();
  }

  ///进度条
  Widget _buildProgressBar() {
    double duration;
    if (!_latestValue.isInitialized) {
      duration = 1.0;
    } else {
      duration = durationToDouble(_latestValue.duration);
    }
    double currentValue =
        _seekPos > 0 ? _seekPos : durationToDouble(_currentPos);
    currentValue = currentValue.clamp(0.0, duration);

    double bufferPos = durationToDouble(_bufferPos);
    bufferPos = bufferPos.clamp(0.0, duration);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 10, left: 10),
        child: ProgressBar(
          progressBarIndicatorImagePath: widget.progressBarIndicatorImagePath,
          colors: sliderColors,
          value: currentValue,
          cacheValue: bufferPos,
          min: 0.0,
          max: duration,
          onChanged: (v) {
            _cancelAndRestartAutoHideTimer();
            setState(() {
              _seekPos = v;
            });
          },
          onChangeEnd: (v) {
            setState(() {
              _currentPos = Duration(milliseconds: _seekPos.toInt());
              videoPlayerController.seekTo(_currentPos);
              _seekPos = -1.0;
            });
          },
        ),
      ),
    );
  }

  ///浮层
  videoAppBarOverlay() {
    return AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: videoAppBar());
  }

  getBatteryLevel() async {
    final level = await battery.batteryLevel;
    if (mounted) {
      setState(() {
        batteryLevel = level;
      });
    }
  }

  videoAppBar() {
    return Container(
      // width: 350.w,
      height: 48 * 1.5 * 1.4,
      padding: const EdgeInsets.only(top: 0, right: 0),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(gradient: blackLinearGradient(fromTop: true)),
      child: Column(
        children: [
          (widget.aspectRatio ?? 16 / 9) > 1 &&
                  controller.isVideoFullScreen.value
              ? Container(
                  alignment: Alignment.topCenter,
                  height: 14,
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      const Spacer(),
                      buildTimeNow(),
                      const Spacer(),
                      buildPower(),
                    ],
                  ),
                )
              : Container(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  color: Colors.white,
                  onPressed: () {
                    if (controller.isVideoFullScreen.value) {
                      print("togglefullscreen");
                      setState(() {
                        chewieController.toggleFullScreen();
                        controller.isVideoFullScreen.value = false;
                        Future.delayed(const Duration(milliseconds: 500), () {
                          flutterDanmakuController.init(areaSize);
                          print("new areasize = $areaSize");
                        });
                      });
                    } else {
                      /// You method to handle back button
                      // Get.back();
                    }
                  },
                ),
                Container(
                  width: 270,
                  child: Text(
                    widget.videoTitle ?? "THIS IS A TEST TITLE",
                    style: subtitleTextMediumWhite,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTimeNow() {
    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(left: 50),
      child: Text(
        '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }

  /// battery status in top right corner
  Widget buildPower() {
    if (batteryState == BatteryState.charging) {
      return Row(
        children: [
          Text(
            '$batteryLevel%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
          const Icon(
            Icons.battery_charging_full_rounded,
            color: Colors.white,
            size: 16,
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Text(
            '$batteryLevel%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
          if (batteryLevel < 14)
            const Icon(
              Icons.battery_1_bar_rounded,
              color: Colors.white,
              size: 16,
            )
          else if (batteryLevel < 28)
            const Icon(
              Icons.battery_2_bar_rounded,
              color: Colors.white,
              size: 16,
            )
          else if (batteryLevel < 42)
            const Icon(
              Icons.battery_3_bar_rounded,
              color: Colors.white,
              size: 16,
            )
          else if (batteryLevel < 56)
            const Icon(
              Icons.battery_4_bar_rounded,
              color: Colors.white,
              size: 16,
            )
          else if (batteryLevel < 70)
            const Icon(
              Icons.battery_5_bar_rounded,
              color: Colors.white,
              size: 16,
            )
          else if (batteryLevel < 84)
            const Icon(
              Icons.battery_6_bar_rounded,
              color: Colors.white,
              size: 16,
            )
          else
            const Icon(
              Icons.battery_full_rounded,
              color: Colors.white,
              size: 16,
            )
        ],
      );
    }
  }
}

/// class for barrage data. change it base on your need
class BarrageData {
  int? id;
  int? createdAt;
  int? updatedAt;
  String? userToken;
  int? postId;
  String? content;
  String? color;
  int? position;
  int? time;

  BarrageData(
      {this.id,
      this.createdAt,
      this.updatedAt,
      this.userToken,
      this.postId,
      this.content,
      this.color,
      this.time,
      this.position});

  BarrageData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    userToken = json['user_token'];
    postId = json['post_id'];
    content = json['content'];
    color = json['color'];
    time = json['time'];
    position = json['position'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['user_token'] = userToken;
    data['post_id'] = postId;
    data['content'] = content;
    data['color'] = color;
    data['time'] = time;
    data['position'] = position;
    return data;
  }
}
