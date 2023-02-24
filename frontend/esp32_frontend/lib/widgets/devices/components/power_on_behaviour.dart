import 'package:esp32_frontend/widgets/devices/components/build_exception.dart';
import 'package:esp32_frontend/widgets/other/my_button.dart';
import 'package:flutter/material.dart';
import 'package:esp32_frontend/util/string_extension.dart';

class PowerOnBehaviourToggle extends StatefulWidget {
  const PowerOnBehaviourToggle(
      {Key? key,
      required this.toggleList,
      required this.onPressed,
      this.alreadySelected})
      : super(key: key);
  final List<Text> toggleList;
  final String? alreadySelected;
  final void Function(String value) onPressed;
  @override
  State<PowerOnBehaviourToggle> createState() => _PowerOnBehaviourToggleState();
}

class _PowerOnBehaviourToggleState extends State<PowerOnBehaviourToggle> {
  List<Text> toggleList = [];
  List<bool> toggleListBool = [];
  @override
  void initState() {
    toggleList = widget.toggleList;
    for (var i = 0; i < toggleList.length; i++) {
      if (toggleList[i].data == null) {
        throw const BuildException("List<Text> must not contain textSpan");
      }
      toggleListBool.add(toggleList[i].data!.toUpperCaseOnlyFirstLetter() ==
              widget.alreadySelected
          ? true
          : false);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return UnselectableToggleButton(
        child: ToggleButtons(
            isSelected: toggleListBool,
            onPressed: (index) {
              for (var i = 0; i < toggleListBool.length; i++) {
                toggleListBool[i] = false;
              }
              toggleListBool[index] = true;
              widget.onPressed(toggleList[index].data!);
            },
            borderRadius: BorderRadius.circular(4.0),
            children: toggleList));
  }
}
