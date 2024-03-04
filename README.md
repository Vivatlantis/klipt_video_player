# klipt_video_player

A video player for flutter with multiple gesture support and added danmaku (bullet/barrage) function inside it.

GitHub: https://github.com/Vivatlantis/klipt_video_player
Author: Royce Zhai

## Description

Everyone loves [chewie](https://pub.dev/packages/chewie), a video player with highly customizable interface. While watching the video, many would like to see or send a danmaku/bullet/barrage (they refer to the same thing!), and klipt_video_player makes everything possible at once, with integrated gesture control to enhance user experience.

The danmaku of the player has the following features, you may:

- Choose the color of danmaku to be sent;
- Choose the position of danmaku: flowing on top or fixed at bottom;
- Adjust the danmaku display area on video player;
- Adjust the flowing speed of danmaku;
- Adjust the displayed font size of danmaku;

The video player support gestures including:

- Long press the video to play in double speed;
- Double tap the video to play/pause video;
- Swipe left/right to quickly seek to a desired position;
- Swipe up/down in left half of screen to adjust video brightness (based on system brightness);
- Swipe up/down in right half of screen to adjust video volume (based on system volume);
- There's also a lock button to block all gestures!



## Preview
Buttons in bottom bar: play/pause; open/close danmaku; danmaku settings; open keyboard to send danmaku; adjust video playback speed; expand/collapse

![sc1](/assets/sc_landscape.jpg)

![sc1](/assets/sc_setting.jpg)


## Installation

In your `[pubspec.yaml]`file within your Flutter Project add `[klipt_video_player]` under dependencies:

```dart
dependencies:
  klipt_video_player: <latest_version>
```

## Using the player

After adding the dependency in your pubspec.yaml file, you can access the player by simply calling the widget as below (there are some additional parameters to be explored):

**Please note: you _MUST_ call "createWithDependencies" as some GetX controller need to be created with this widget to make it functional.**

```dart
import 'package:klipt_video_player/klipt_video_player.dart';
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Center(
      /// MUST use createWithDependencies
      child: KliptVideoView.createWithDependencies(
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
```

The danmaku list example is provided below: it is simply a list containing `[DanmakuData]`, which its `[content]`, ` [time]` and `[position]` being
the required fields. Other optional parameters and explanations can be found in [danmanku.dart] file

```dart
final List<DanmakuData> list = [
  DanmakuData(content: "a initial danmaku", time: 2000, position: 1),
  DanmakuData(content: "a fantastic danmaku", time: 2500, position: 1),
  DanmakuData(content: "a working danmaku", time: 3000, position: 1),
  DanmakuData(content: "a bottom danmaku", time: 3500, position: 2)
];
```

# Acknowledgements:

This project is developed based on:

- https://pub.dev/packages/chewie
- https://pub.dev/packages/flutter_danmaku
- https://pub.dev/packages/fplayer

# TODO LIST:

- Fix bugs e.g. setState() called during build .etc

- Listen for feedback and add more parameters to the interface

  

  