import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../application_controller.dart';

class ToggleBulletButton extends StatefulWidget {
  final bool backgroundIsWhite;
  final VoidCallback onToggle;

  const ToggleBulletButton(
      {super.key, required this.backgroundIsWhite, required this.onToggle});

  @override
  _ToggleBulletButtonState createState() => _ToggleBulletButtonState();
}

class _ToggleBulletButtonState extends State<ToggleBulletButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Obx(() {
        bool isToggled =
            Get.find<ApplicationController>().isBulletSwitchOn.value;

        return Image.asset(
          isToggled
              ? widget.backgroundIsWhite
                  ? 'assets/bullet_on.png'
                  : 'assets/bullet_on_white.png'
              : 'assets/bullet_off.png',
          height: 30,
          width: 30,
        );
      }),
      onTap: () {
        Get.find<ApplicationController>().toggleBulletSwitch();
      },
    );
  }
}
