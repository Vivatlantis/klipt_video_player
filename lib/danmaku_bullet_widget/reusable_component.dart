import 'package:flutter/material.dart';

import 'bullet_button.dart';

blackLinearGradient({bool fromTop = false}) {
  return LinearGradient(
    begin: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
    end: fromTop ? Alignment.bottomCenter : Alignment.topCenter,
    colors: const [
      Colors.black54,
      Colors.black45,
      Colors.black38,
      Colors.black26,
      Colors.black12,
      Colors.transparent
    ],
  );
}

/// 弹幕开关的按钮，目前可以切换按钮图样
GestureDetector buildBulletSwitch(
    bool backgroundIsWhite, VoidCallback onToggle) {
  return GestureDetector(
    onTap: onToggle,
    child: Container(
      height: 48 * 1.5,
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 8),
      child: ToggleBulletButton(
        backgroundIsWhite: backgroundIsWhite,
        onToggle: onToggle,
      ),
    ),
  );
}
