import 'dart:async';

import 'package:flutter/material.dart';

/// Default builder generate default FVolToast UI
Widget defaultFVolumeToast(double value, Stream<double> emitter) {
  return _FSliderToast(value, 0, emitter);
}

Widget defaultFBrightnessToast(double value, Stream<double> emitter) {
  return _FSliderToast(value, 1, emitter);
}

class _FSliderToast extends StatefulWidget {
  final Stream<double> emitter;
  final double initial;

  // type 0 volume
  // type 1 screen brightness
  final int type;

  const _FSliderToast(this.initial, this.type, this.emitter);

  @override
  _FSliderToastState createState() => _FSliderToastState();
}

class _FSliderToastState extends State<_FSliderToast> {
  double value = 0;
  StreamSubscription? subs;

  @override
  void initState() {
    super.initState();
    value = widget.initial;
    subs = widget.emitter.listen((v) {
      setState(() {
        value = v;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    subs?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    final type = widget.type;
    if (value <= 0) {
      iconData = type == 0 ? Icons.volume_mute : Icons.brightness_low;
    } else if (value < 0.5) {
      iconData = type == 0 ? Icons.volume_down : Icons.brightness_medium;
    } else {
      iconData = type == 0 ? Icons.volume_up : Icons.brightness_high;
    }

    return Align(
      alignment: const Alignment(0, -0.4),
      child: Card(
        color: const Color(0x33000000),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                iconData,
                color: Colors.white,
              ),
              Container(
                width: 100,
                height: 1.5,
                margin: const EdgeInsets.only(left: 8),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.black,
                  valueColor: const AlwaysStoppedAnimation(
                      Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
