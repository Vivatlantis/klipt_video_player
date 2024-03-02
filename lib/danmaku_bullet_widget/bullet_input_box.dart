import 'dart:io';

import 'package:klipt_video_player/danmaku_bullet_widget/bullet_color_selection.dart';
import 'package:klipt_video_player/textstyles.dart';
import 'package:flutter/material.dart';

///弹幕输入框，悬浮在键盘上方
class BulletInput extends StatefulWidget {
  final Color currentSelectedColor;
  final Function(Color) onClickToClose;
  final Function(String, Color, bool) onBulletSubmit;
  final TextEditingController editingController;
  final bool isFullScreen;
  const BulletInput(
      {Key? key,
      required this.onBulletSubmit,
      required this.editingController,
      required this.onClickToClose,
      required this.isFullScreen,
      required this.currentSelectedColor})
      : super(key: key);

  @override
  State<BulletInput> createState() => _BulletInputState();
}

class _BulletInputState extends State<BulletInput> {
  Color currentSelectedColor = Colors.white;
  bool bottomBullet = false;
  @override
  void initState() {
    currentSelectedColor = widget.currentSelectedColor;
    super.initState();
  }

  final FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 空白区域点击关闭弹框
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
                widget.onClickToClose(currentSelectedColor);
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          Container(
            // height: MediaQuery.of(context).viewInsets.bottom,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    spreadRadius: 2,
                    blurRadius: 2,
                    offset: Offset(0, 2),
                  )
                ]),
            padding: EdgeInsets.only(
                left: Platform.isIOS && widget.isFullScreen ? 60 : 0,
                right: Platform.isIOS && widget.isFullScreen ? 60 : 0,
                bottom: (focusNode.hasFocus &&
                        MediaQuery.of(context).viewInsets.bottom > 100)
                    ? MediaQuery.of(context).viewInsets.bottom - 110
                    : 120),

            // Platform.isIOS
            //     ? (widget.isFullScreen ? 110 : 230)
            //     : (widget.isFullScreen ? 110 : 180)),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildSendBulletSetting(),
                    _buildInput(widget.editingController, context),
                    _buildSendBtn(widget.editingController, context)
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 30,
                  child: bulletPositionSelection(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 40,
                  child: bulletColorSelection(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Row bulletColorSelection() {
    return Row(
      children: [
        Container(
            // alignment: Alignment.topCenter,
            width: 60,
            // height: 60,
            padding: const EdgeInsets.only(left: 10),
            child: const Text(
              "Color",
              style: smallTextRegularLightGrey,
            )),
        const SizedBox(width: 6),
        Expanded(
          child: BulletColorSelection(
            currentColor: currentSelectedColor,
            onColorSelected: (color) {
              setState(() {
                currentSelectedColor = color;
              });
            },
          ),
        ),
      ],
    );
  }

  Row bulletPositionSelection() {
    return Row(
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.only(left: 10),
          child: const Text(
            "Position",
            style: smallTextRegularLightGrey,
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            if (bottomBullet) {
              setState(() {
                bottomBullet = false;
              });
            }
          },
          child: Container(
            color: Colors.transparent,
            child: Row(
              children: [
                Icon(
                  Icons.vertical_align_top,
                  color: bottomBullet ? Colors.grey : Colors.blue,
                ),
                Text("Flowing on Top",
                    style: TextStyle(
                      color: bottomBullet ? Colors.grey : Colors.blue,
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: () {
            if (!bottomBullet) {
              setState(() {
                bottomBullet = true;
              });
            }
          },
          child: Container(
            color: Colors.transparent,
            child: Row(
              children: [
                Icon(
                  Icons.vertical_align_bottom,
                  color: bottomBullet ? Colors.blue : Colors.grey,
                ),
                Text(
                  "Fixed at Bottom",
                  style: TextStyle(
                      color: bottomBullet ? Colors.blue : Colors.grey),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  _buildSendBulletSetting() {
    return InkWell(
      onTap: () {
        if (focusNode.hasFocus) {
          focusNode.unfocus();
        } else {
          focusNode.requestFocus();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: const Icon(
          Icons.text_format,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }

  _buildInput(TextEditingController editingController, BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          autofocus: true,
          controller: editingController,
          focusNode: focusNode,
          onSubmitted: (value) {
            Navigator.pop(context);
            widget.onBulletSubmit(value, currentSelectedColor, bottomBullet);
          },
          decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
              border: InputBorder.none,
              hintStyle: smallTextRegularLightGrey,
              hintText: "Fire the very bullet you want!"),
        ),
      ),
    );
  }

  _buildSendBtn(TextEditingController editingController, BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        widget.onBulletSubmit(
            editingController.text, currentSelectedColor, bottomBullet);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        child: const Icon(
          Icons.send_rounded,
          color: Colors.grey,
          size: 24,
        ),
      ),
    );
  }
}
