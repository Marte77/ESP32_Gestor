import 'package:esp32_frontend/paginas/esp32.dart';
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

  void ligar() {
    var url = Uri.http(widget.esp32.ipaddress,
        "mode/$modoAnterior?r=${widget.esp32.cor.red},g=${widget.esp32.cor.green},b=${widget.esp32.cor.blue},w=${Esp32.map(widget.esp32.cor.alpha.toDouble(), 0, 255, 255, 0)},br=255");
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
        child: Column(children: [
          Text(widget.esp32.ipaddress),
          Text(widget.esp32.modo),
          Row(children: [
            const Text("Cor:         "),
            Container(
              color: widget.esp32.cor,
              width: 30,
              height: 30,
            ),
          ]),
          ElevatedButton(
            onPressed: () => desligar(),
            child: const Text("Desligar"),
          ),
          ElevatedButton(
              onPressed: () => ligar(),
              child: Text("Voltar ao modo: $modoAnterior"))
        ]),
      ),
    );
  }
}
