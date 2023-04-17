import 'package:esp32_frontend/pages/esp32.dart';
import 'package:esp32_frontend/widgets/other/my_button.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Esp32MainCard extends StatefulWidget {
  const Esp32MainCard({Key? key, required this.esp32}) : super(key: key);
  final Esp32 esp32;
  @override
  State<Esp32MainCard> createState() => _Esp32MainCardState();
}

class _Esp32MainCardState extends State<Esp32MainCard> {
  String modoAnterior = "";
  int brightnessVal = 254;
  @override
  void initState() {
    modoAnterior = widget.esp32.modo;
    super.initState();
  }

  void desligar() {
    var url = Uri.http(widget.esp32.ipaddress,
        "mode/turnOff?r=${widget.esp32.cor.red},g=${widget.esp32.cor.green},b=${widget.esp32.cor.blue},w=${Esp32.map(widget.esp32.cor.alpha.toDouble(), 0, 255, 255, 0)},br=255");
    http.get(url).then((value) => null).onError((error, stackTrace) {
      return null;
    });
    widget.esp32.modo = "turnOff";
    setState(() {});
  }

  void ligar(String modo) {
    if (modo == "corEstatica") {
      widget.esp32.cor = const Color.fromARGB(0, 0, 0, 0);
    }
    var url = Uri.http(widget.esp32.ipaddress,
        "mode/$modo?r=${widget.esp32.cor.red},g=${widget.esp32.cor.green},b=${widget.esp32.cor.blue},w=${Esp32.map(widget.esp32.cor.alpha.toDouble(), 0, 255, 255, 0)},br=255");
    http.get(url).then((value) => null).onError((error, stackTrace) {
      return null;
    });
    widget.esp32.modo = modoAnterior;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Column(
          children: [
            Text(widget.esp32.ipaddress),
            Text(widget.esp32.modo),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Cor:         "),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  child: Container(
                    width: 30,
                    height: 30,
                    color: widget.esp32.cor,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Slider(
                  value: brightnessVal.toDouble(),
                  onChanged: (val) {
                    setState(() {
                      brightnessVal = val.round();
                    });
                  },
                  label: brightnessVal.toString(),
                  min: 0,
                  max: 254,
                ),
                UnselectableElevatedButton(
                  child: ElevatedButton(
                    onPressed: () => {},
                    child: const Text("Enviar Lumin."),
                  ),
                )
              ],
            ),
            UnselectableElevatedButton(
              child: ElevatedButton(
                onPressed: () => desligar(),
                child: const Text("Desligar"),
              ),
            ),
            UnselectableElevatedButton(
              child: ElevatedButton(
                  onPressed: () => ligar(modoAnterior),
                  child: Text("Voltar ao modo: $modoAnterior")),
            ),
            UnselectableElevatedButton(
                child: ElevatedButton(
                    onPressed: () => ligar("corEstatica"),
                    child: const Text("Ligar"))),
          ],
        ),
      ),
    );
  }
}
