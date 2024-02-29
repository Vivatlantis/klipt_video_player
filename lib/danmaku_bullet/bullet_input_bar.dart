import 'package:flutter/material.dart';

class BulletInputBar extends StatefulWidget {
  final VoidCallback onTapFunction;
  final double? width;
  const BulletInputBar({Key? key, required this.onTapFunction, this.width})
      : super(key: key);

  @override
  _BulletInputBarState createState() => _BulletInputBarState();
}

class _BulletInputBarState extends State<BulletInputBar> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTapFunction,
      child: Container(
        width: widget.width ?? 200,
        height: 30,
        padding: const EdgeInsets.only(left: 8, right: 8),
        margin: const EdgeInsets.only(right: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.9),
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(15)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("click me to send a bullet"),
            Icon(Icons.send, color: Colors.purpleAccent, size: 20)
          ],
        ),
      ),
    );
  }
}
