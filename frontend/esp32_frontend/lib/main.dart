import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class esp32 {
  esp32(this.ipaddress, this.timestamp);
  String ipaddress;
  String timestamp;
  @override
  bool operator ==(other) => other is esp32 && (other.ipaddress == ipaddress);

  @override
  int get hashCode => ipaddress.hashCode;
}

class _MyHomePageState extends State<MyHomePage> {
  List<DropdownMenuItem<esp32>> esps = [
    DropdownMenuItem(child: const Text(""), value: esp32("", ""))
  ];
  esp32? selected, emptyesp;
  List<String> metodos = [
    'fadeEstatico',
    'corEstatica',
    'preencherUmAUm',
    'preencherUmAUmBounce',
    'arcoIris',
    'arcoIrisCycle',
    'turnOff',
  ];
  final formGlobalKey = GlobalKey<FormState>();
  String selectedMetodo = 'fadeEstatico';
  Color? selectedColor = const Color.fromARGB(255, 252, 2, 149);
  int brightnessVal = 255;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    emptyesp = esps.first.value;
    timer = Timer.periodic(const Duration(seconds: 15), ((timer) {
      initAsync();
    }));
  }

  static double map(
      double x, double in_min, double in_max, double out_min, double out_max) {
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
  }

  void initAsync() async {
    var url = Uri.http('localhost:8080', 'getall');
    var res = await http.get(url);
    if (res.statusCode == 200) {
      List<dynamic> parsed = jsonDecode(res.body)['dados'];
      esps.clear();
      for (var esp in parsed) {
        esps.add(DropdownMenuItem(
          value: esp32(
              esp['ipaddress']!,
              (DateTime.fromMillisecondsSinceEpoch(
                      int.parse((esp['timestamp']! as String).split(".").first))
                  .toIso8601String())),
          child: Text(esp['ipaddress']!),
        ));
      }
      if (esps.isEmpty) {
        selected = emptyesp;
      } else {
        selected = esps.first.value;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Scrollbar(
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kIsWeb ? 55 : 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MaterialBanner(
                content: const Text(
                    "O valor Alpha na selecao de cores, define a cor Branca dos leds.\nCertos modos ignoram a cor selecionada"),
                leading: const CircleAvatar(child: Icon(Icons.warning)),
                actions: [
                  TextButton(
                    child: const Text('             '),
                    onPressed: () {},
                  ),
                  TextButton(
                    child: const Text('             '),
                    onPressed: () {},
                  ),
                ],
              ),
              Form(
                key: formGlobalKey,
                child: Column(children: [
                  esps.isNotEmpty
                      ? DropdownButton(
                          value: selected,
                          items: esps,
                          onChanged: (esp) {
                            setState(() {
                              selected = esp as esp32;
                            });
                          })
                      : const Text(''),
                  DropdownButton(
                    value: selectedMetodo,
                    items: List.generate(
                        metodos.length,
                        (index) => DropdownMenuItem(
                              value: metodos[index],
                              child: Text(metodos[index]),
                            )),
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() {
                          selectedMetodo = val;
                        });
                      }
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: ((context) {
                          return AlertDialog(
                            titlePadding: const EdgeInsets.all(0),
                            contentPadding: const EdgeInsets.all(0),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: selectedColor!,
                                onColorChanged: ((value) {
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
                                onPressed: () => Navigator.of(context).pop(),
                              )
                            ],
                          );
                        }),
                      );
                    },
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(selectedColor)),
                    child: const Text("Cor selecionada"),
                  ),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    initialValue: brightnessVal.toString(),
                    validator: (value) {
                      if (value == null) return "Valor nao pode ser vazio";
                      var aux = int.tryParse(value);
                      if (aux == null) return "Valor tem de ser um numero";
                      if (aux > 255 || aux < 0) {
                        return "Valor tem de estar entre 0 e 255";
                      }
                      return null;
                    },
                    onChanged: (value) {
                      var aux = int.tryParse(value);
                      if (aux == null || aux > 255 || aux < 0) {
                        setState(() {
                          brightnessVal = 255;
                        });
                      } else {
                        setState(() {
                          brightnessVal = int.parse(value);
                        });
                      }
                    },
                  ),
                  ElevatedButton(
                    onPressed: (() async {
                      if (!formGlobalKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Valor do brilho incorreto")));
                        return;
                      }
                      if (selected == null ||
                          selectedColor == null ||
                          selected!.ipaddress.isEmpty ||
                          selectedMetodo.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Sem as informacoes todas")));
                        return;
                      }
                      var url = Uri.http(selected!.ipaddress,
                          "mode/$selectedMetodo?r=${selectedColor!.red},g=${selectedColor!.green},b=${selectedColor!.blue},w=${map(selectedColor!.alpha.toDouble(), 0, 255, 255, 0)},br=$brightnessVal");
                      http
                          .get(url)
                          .then((value) => null)
                          .onError((error, stackTrace) {
                        print(error);
                        return null;
                      });
                    }),
                    child: const Text("Enviar"),
                  )
                ]),
              )
            ],
          ),
        )),
      )),
    );
  }
}
