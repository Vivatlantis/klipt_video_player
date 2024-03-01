import 'package:chewie_with_danmaku/flutter_danmaku/flutter_danmaku_controller.dart';
import 'package:chewie_with_danmaku/textstyles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BulletController extends GetxController {
  RxDouble opacityValue = 100.0.obs;
  RxDouble fontSizeValue = 14.0.obs;

  RxString displayArea = '1/2'.obs;
  RxDouble displayAreaValue = 0.50.obs;

  RxString bulletSpeed = 'Normal'.obs;
  RxDouble bulletSpeedValue = 1.0.obs;

  void updateDisplayArea() {
    if (displayAreaValue.value == 0.25) {
      displayArea.value = '1/4';
    } else if (displayAreaValue.value == 0.50) {
      displayArea.value = '1/2';
    } else if (displayAreaValue.value == 0.75) {
      displayArea.value = '3/4';
    } else {
      displayArea.value = 'Full';
    }
  }

  void updateBulletSpeed() {
    if (bulletSpeedValue.value == 0.5) {
      bulletSpeed.value = 'Slow';
    } else if (bulletSpeedValue.value == 1) {
      bulletSpeed.value = 'Normal';
    } else if (bulletSpeedValue.value == 1.5) {
      bulletSpeed.value = 'Fast';
    } else {
      bulletSpeed.value = 'Rapid';
    }
  }
}

class BulletSetting extends StatefulWidget {
  final FlutterDanmakuController flutterDanmakuController;
  final Color? primaryColor;
  const BulletSetting({
    required this.flutterDanmakuController,
    Key? key,
    this.primaryColor,
  }) : super(key: key);

  @override
  State<BulletSetting> createState() => _BulletSettingState();
}

class _BulletSettingState extends State<BulletSetting> {
  final BulletController controller = Get.put(BulletController());
  late FlutterDanmakuController flutterDanmakuController;

  @override
  void initState() {
    super.initState();
    flutterDanmakuController = widget.flutterDanmakuController;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.only(top: 80, bottom: 80, right: 30, left: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          opacity(),
          displayArea(),
          fontSize(),
          bulletSpeed(),
        ],
      ),
    );
  }

  Row bulletSpeed() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text("Bullet Speed",
              style: subtitleTextRegularWhite.copyWith(fontSize: 14)),
        ),
        Flexible(
          child: Obx(
            () => SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                trackHeight: 2,
              ),
              child: Slider(
                value: controller.bulletSpeedValue.value,
                activeColor: widget.primaryColor ?? Colors.pinkAccent,
                inactiveColor:
                    widget.primaryColor ?? Colors.pinkAccent.withOpacity(0.5),
                min: 0.5,
                max: 2.0,
                divisions: 3,
                onChanged: (newValue) {
                  controller.bulletSpeedValue.value = newValue;
                  controller.updateBulletSpeed();
                  flutterDanmakuController.changeRate(newValue);
                },
              ),
            ),
          ),
        ),
        Obx(() => rightSideText(controller.bulletSpeed.value)),
      ],
    );
  }

  Row fontSize() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 84,
          child: Text("Font Size",
              style: subtitleTextRegularWhite.copyWith(fontSize: 14)),
        ),
        Flexible(
          child: Obx(
            () => SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                trackHeight: 2,
              ),
              child: Slider(
                value: controller.fontSizeValue.value,
                activeColor: widget.primaryColor ?? Colors.pinkAccent,
                inactiveColor:
                    widget.primaryColor ?? Colors.pinkAccent.withOpacity(0.5),
                min: 10,
                max: 20,
                onChanged: (newValue) {
                  flutterDanmakuController
                      .changeBulletTextSize(newValue.toInt());
                  controller.fontSizeValue.value = newValue;
                },
              ),
            ),
          ),
        ),
        Obx(() => rightSideText(
            '${controller.fontSizeValue.value.toStringAsFixed(0)}pt'))
      ],
    );
  }

  Row displayArea() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 84,
          child: Text("Display Area",
              style: subtitleTextRegularWhite.copyWith(fontSize: 14)),
        ),
        Flexible(
          child: Obx(
            () => SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                trackHeight: 2,
              ),
              child: Slider(
                value: controller.displayAreaValue.value,
                activeColor: widget.primaryColor ?? Colors.pinkAccent,
                inactiveColor:
                    widget.primaryColor ?? Colors.pinkAccent.withOpacity(0.5),
                min: 0.25,
                max: 1.0,
                divisions: 3,
                onChanged: (newValue) {
                  setState(() {
                    controller.displayAreaValue.value = newValue;
                    controller.updateDisplayArea();
                    flutterDanmakuController.changeShowArea(newValue);
                  });
                },
              ),
            ),
          ),
        ),
        Obx(() => rightSideText(controller.displayArea.value))
      ],
    );
  }

  Row opacity() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
            width: 84,
            child: Text("Opacity",
                style: subtitleTextRegularWhite.copyWith(fontSize: 14))),
        Flexible(
          child: Obx(
            () => SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                trackHeight: 2,
              ),
              child: Slider(
                value: controller.opacityValue.value,
                activeColor: widget.primaryColor ?? Colors.pinkAccent,
                inactiveColor:
                    widget.primaryColor ?? Colors.pinkAccent.withOpacity(0.5),
                min: 0,
                max: 100,
                onChanged: (newValue) {
                  flutterDanmakuController.changeOpacity(newValue / 100);
                  controller.opacityValue.value = newValue;
                },
              ),
            ),
          ),
        ),
        Obx(() => rightSideText(
            '${controller.opacityValue.value.toStringAsFixed(0)}%')),
      ],
    );
  }

  Container rightSideText(String text) {
    return Container(
        width: 50,
        child: Text(text,
            textAlign: TextAlign.left,
            style: subtitleTextRegularWhite.copyWith(fontSize: 14)));
  }
}
