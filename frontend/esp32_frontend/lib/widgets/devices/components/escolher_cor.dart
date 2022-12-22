import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// deves mandar alterar a cor no onClosePopup e guardar o estado da cor no onChangeColor
class EscolherCor extends StatefulWidget {
  const EscolherCor(
      {Key? key,
      required this.onChangeColor,
      required this.onClosePopup,
      required this.color,
      required this.context})
      : super(key: key);
  final Color color;
  final void Function(Color newColor) onChangeColor;
  final void Function() onClosePopup;
  final BuildContext context;
  @override
  State<EscolherCor> createState() => _EscolherCorState();
}

class _EscolherCorState extends State<EscolherCor> {
  late Color selectedColor;
  @override
  void initState() {
    selectedColor = widget.color;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: ((context) {
            return AlertDialog(
              titlePadding: const EdgeInsets.all(0),
              contentPadding: const EdgeInsets.all(0),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: selectedColor,
                  onColorChanged: ((value) {
                    widget.onChangeColor(value);
                    setState(() {
                      selectedColor = value;
                    });
                  }),
                  portraitOnly: true,
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Fechar"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClosePopup();
                  },
                )
              ],
            );
          }),
        );
      },
      style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(selectedColor)),
      child: const Text("Cor selecionada"),
    );
  }
}
