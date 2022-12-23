import 'package:flutter/material.dart';

class ColorTempWithPreset extends StatefulWidget {
  const ColorTempWithPreset(
      {Key? key,
      required this.onPressed,
      required this.onChangeEnd,
      required this.colorTempTemplatesBool,
      required this.colorTempTemplatesNames,
      required this.value,
      required this.min,
      required this.max})
      : super(key: key);
  final void Function(int index) onPressed;
  final void Function(double value) onChangeEnd;
  final List<bool> colorTempTemplatesBool;
  final List<Text> colorTempTemplatesNames;
  final double value, min, max;
  @override
  State<ColorTempWithPreset> createState() => _ColorTempWithPresetState();
}

class _ColorTempWithPresetState extends State<ColorTempWithPreset> {
  double value = 0;
  List<bool> selectedVal = [];
  @override
  void initState() {
    value = widget.value < widget.min
        ? widget.min
        : widget.value > widget.max
            ? widget.max
            : widget.value;

    assert(widget.colorTempTemplatesBool.length ==
        widget.colorTempTemplatesNames.length);
    selectedVal = widget.colorTempTemplatesBool;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ToggleButtons(
            isSelected: widget.colorTempTemplatesBool,
            onPressed: (index) {
              widget.onPressed(index);
              setState(() {
                for (var i = 0; i < selectedVal.length; i++) {
                  selectedVal[i] = false;
                }
                selectedVal[index] = true;
                value = widget.value;
              });
            },
            borderRadius: BorderRadius.circular(4.0),
            children: widget.colorTempTemplatesNames),
        Text("Temperatura: ${value.round()}"),
        Slider(
          value: value,
          min: widget.min,
          max: widget.max,
          label: value.round().toString(),
          onChanged: (val) {
            setState(() {
              value = val;
            });
          },
          onChangeEnd: (value) {
            widget.onChangeEnd(value);
          },
        )
      ],
    );
  }
}
