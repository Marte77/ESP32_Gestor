import 'package:esp32_frontend/widgets/devices/components/build_exception.dart';
import 'package:flutter/material.dart';

class EfeitosDropdown extends StatefulWidget {
  const EfeitosDropdown({Key? key, required this.list, required this.onChanged})
      : super(key: key);
  final List<Text> list;
  final void Function(String value) onChanged;
  @override
  State<EfeitosDropdown> createState() => _EfeitosDropdownState();
}

class _EfeitosDropdownState extends State<EfeitosDropdown> {
  List<Text> list = [];
  String effectChosen = "";
  List<DropdownMenuItem<String>> dropDownList = [];
  @override
  void initState() {
    list = widget.list;
    for (var text in widget.list) {
      if (text.data == null) {
        throw const BuildException(
            "List<Text> must not have any TextSpan widgets");
      }
      dropDownList.add(DropdownMenuItem(
        value: text.data,
        child: text,
      ));
    }

    effectChosen = widget.list.first.data!;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 5),
          child: Text("Efeitos:"),
        ),
        DropdownButton<String>(
          value: effectChosen,
          onChanged: (value) {
            if (value != null) {
              widget.onChanged(value);
              setState(() {
                effectChosen = value;
              });
            }
          },
          items: dropDownList,
        ),
      ],
    );
  }
}
