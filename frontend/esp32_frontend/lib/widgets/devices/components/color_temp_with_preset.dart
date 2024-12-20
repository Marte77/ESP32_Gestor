import 'package:esp32_frontend/widgets/other/my_button.dart';
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
    checkValue();
    assert(widget.colorTempTemplatesBool.length ==
        widget.colorTempTemplatesNames.length);
    selectedVal = widget.colorTempTemplatesBool;
    super.initState();
  }

  checkValue() {
    value = widget.value < widget.min
        ? widget.min
        : widget.value > widget.max
            ? widget.max
            : widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Temperatura: ${value.round()}"),
        MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Slider(
              value: value,
              min: widget.min,
              max: widget.max,
              label: value.round().toString(),
              onChanged: (val) {
                setState(() {
                  value = val;
                });
              },
              onChangeEnd: (val) {
                widget.onChangeEnd(val);
              },
            )),
        UnselectableToggleButton(
            child: ToggleButtons(
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
                children: widget.colorTempTemplatesNames)),
      ],
    );
  }
}
