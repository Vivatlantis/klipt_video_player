import 'package:flutter/material.dart';

final List<Color> colors = [
  const Color(0xFFFFFFFF),
  const Color(0xFFFF0000),
  const Color(0xFF00FF00),
  const Color(0xFF0000FF),
  const Color(0xFFFFEB3B),
  const Color(0xFF9C27B0),
  const Color(0xFFFF9800),
  const Color(0xFF795548),
  const Color(0xFFE91E63),
  const Color(0xFFCDDC39),
  const Color(0xFF009688),
  const Color(0xFF3F51B5),
];

Color stringToColor(String colorString) {
  String valueString = colorString
      .split('(0x')[1]
      .split(')')[0]; // Extract the hex value from the string
  int value = int.parse(valueString, radix: 16); // Convert hex value to integer
  return Color(value);
}

class BulletColorSelection extends StatefulWidget {
  final ValueChanged<Color> onColorSelected;
  final Color currentColor;

  const BulletColorSelection(
      {super.key, required this.onColorSelected, required this.currentColor});

  @override
  _BulletColorSelectionState createState() => _BulletColorSelectionState();
}

class _BulletColorSelectionState extends State<BulletColorSelection> {
  Color? selectedColor;
  @override
  void initState() {
    selectedColor = widget.currentColor;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0, // gap between containers
      children: colors.map((color) {
        bool isSelected = selectedColor == color;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedColor = color;
              widget.onColorSelected(color);
            });
          },
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 32.0, // Increased size to accommodate both borders
                height: 24.0, // Increased size to accommodate both borders
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1.0),
                  borderRadius:
                      BorderRadius.circular(8.0), // Slightly larger radius
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: Colors.white, width: 1.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        border: Border.all(color: Colors.white, width: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check,
                          size: 12, color: Colors.white),
                    ),
                  ),
                )
            ],
          ),
        );
      }).toList(),
    );
  }
}
