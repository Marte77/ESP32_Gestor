import 'package:flutter/material.dart';

class LuminosidadeSlider extends StatefulWidget {
  const LuminosidadeSlider(
      {Key? key,
      required this.brightness,
      required this.min,
      required this.max,
      required this.onChangeEnd})
      : super(key: key);
  final double brightness, max, min;
  final void Function(double brightness) onChangeEnd;
  @override
  State<LuminosidadeSlider> createState() => _LuminosidadeSliderState();
}

class _LuminosidadeSliderState extends State<LuminosidadeSlider> {
  double brightness = 0;
  @override
  void initState() {
    brightness = widget.brightness;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Luminosidade: ${brightness.round()}"),
        MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Slider(
              value: brightness,
              min: widget.min,
              max: widget.max,
              label: brightness.round().toString(),
              onChanged: (value) {
                setState(() {
                  brightness = value;
                });
              },
              onChangeEnd: (value) {
                widget.onChangeEnd(value);
              },
            ))
      ],
    );
  }
}
