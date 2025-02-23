import 'dart:async';

import 'package:esp32_frontend/widgets/other/my_button.dart';
import 'package:esp32_frontend/widgets/other/navdrawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/string_extension.dart';

class PaginaEsp32 extends StatefulWidget {
  const PaginaEsp32({Key? key}) : super(key: key);

  @override
  State<PaginaEsp32> createState() => _PaginaEsp32State();
}

class Esp32 {
  Esp32(this.ipaddress, this.timestamp, this.modo, this.cor, this.waitTime) {
    if (modo.toLowerCase() == "desligarleds") {
      modo = "turnOff";
    }
  }
  String ipaddress;
  String timestamp;
  String modo;
  int waitTime;
  Color cor;
  @override
  bool operator ==(other) => other is Esp32 && (other.ipaddress == ipaddress);

  @override
  int get hashCode => ipaddress.hashCode;

  @override
  String toString() {
    return "ip $ipaddress; timestamp $timestamp; modo $modo; wait $waitTime; cor ${cor.toString()}";
  }

  static double map(
      double x, double inMin, double inMax, double outMin, double outMax) {
    return (x - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
  }
}

class _PaginaEsp32State extends State<PaginaEsp32> {
  List<DropdownMenuItem<Esp32>> esps = [
    DropdownMenuItem(
      value: Esp32("", "", "", Colors.pink, 50),
      child: const Text(""),
    )
  ];
  Map<String, Map<String, dynamic>> mapEsps = {};
  Esp32? selected, emptyesp;
  List<String> metodos = [
    'fadeEstatico',
    'corEstatica',
    'preencherUmAUm',
    'preencherUmAUmBounce',
    'arcoIris',
    'arcoIrisCycle',
    'cintilarEstrelas',
    'turnOff',
    'fire'
  ];
  RGBMode? rgbMode = RGBMode.grbw;
  final formGlobalKey = GlobalKey<FormState>();
  String selectedMetodo = 'fadeEstatico';
  Color selectedColor = Colors.pink;
  int brightnessVal = 254;
  int waitTime = 50;
  bool isWaitButtonEnabled = true;
  Timer? timer;
  bool isFullWhite = false;
  @override
  void initState() {
    super.initState();
    emptyesp = esps.first.value;
    initAsync();
    timer = Timer.periodic(const Duration(seconds: 90), ((timer) {
      initAsync();
    }));
  }

  void initAsync() async {
    var sp = await SharedPreferences.getInstance();
    var ip = sp.getString(SHARED_PREFS_SERVER_KEY)!;
    var port = sp.getString(SHARED_PREFS_SERVER_PORT_KEY)!;
    var url = Uri.http('$ip:$port', 'getall');
    var res = await http.get(url);
    if (res.statusCode == 200) {
      List<dynamic> parsed = jsonDecode(res.body)['dados'];
      esps.clear();
      mapEsps.clear();
      for (var esp in parsed) {
        List<String> cores = (esp['cor']! as String)
            .replaceAll("(", "")
            .replaceAll(")", "")
            .split(",");
        esps.add(DropdownMenuItem(
          value: Esp32(
              esp['ipaddress']!,
              (DateTime.fromMillisecondsSinceEpoch(
                      int.parse((esp['timestamp']! as String).split(".").first))
                  .toIso8601String()),
              esp['modo'] as String,
              Color.fromARGB(
                  Esp32.map(int.parse(cores.last).toDouble(), 0, 255, 255, 0)
                      .toInt(),
                  int.parse(cores.first),
                  int.parse(cores[1]),
                  int.parse(cores[2])),
              esp['waittime'] as int),
          child: Text(esp['ipaddress']!),
        ));
      }
      if (esps.isEmpty) {
        selected = emptyesp;
      } else {
        selected = esps.first.value;
        if (selected!.cor.blue != 0 &&
            selected!.cor.green != 0 &&
            selected!.cor.red != 0) {
          //colorTheme.add(generateMaterialColor(color: selected!.cor));
        }
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
      ),
      drawer: const NavDrawer(),
      body: Center(
          child: Scrollbar(
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: kIsWeb ? 55 : 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              bannerComponent(context),
              const Padding(
                padding: EdgeInsets.only(bottom: 15),
                child: Divider(),
              ),
              formComponent(context)
            ],
          ),
        )),
      )),
    );
  }

  Widget bannerComponent(BuildContext context) {
    return MaterialBanner(
      content: const Padding(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        child: Text(
            "O valor Alpha na selecao de cores, define a cor Branca dos leds.\nCertos modos ignoram a cor e brilho selecionados"),
      ),
      leading: const CircleAvatar(child: Icon(Icons.warning)),
      actions: [
        UnselectableTextButton(
          child: TextButton(
            child: const Text('             '),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget formComponent(BuildContext context) {
    return Form(
      key: formGlobalKey,
      child: Column(children: [
        selectEspComponent(context),
        waitTimeComponent(context),
        selectRBGModeComponent(context),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Divider(),
        ),
        selectLightModeComponent(context),
        selectWhetherToUseWhiteComponent(context),
        selectLEDColorComponent(context),
        /*
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
                  */
        const Divider(),
        selectLEDBrightnessComponent(context),
        const SizedBox(
          height: 10,
        ),
        sendFormButtonComponent(context),
      ]),
    );
  }

  Widget selectRBGModeComponent(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DropdownButton(
          items: List.generate(
              RGBMode.values.length,
              (index) => DropdownMenuItem(
                  value: RGBMode.values.elementAt(index),
                  child: Text(RGBMode.values.elementAt(index).toString()))),
          value: rgbMode,
          onChanged: (rgb) {
            if (rgb != null) {
              setState(() {
                rgbMode = rgb;
              });
            }
          },
        ),
        const SizedBox(
          width: 50,
        ),
        UnselectableElevatedButton(
            child: ElevatedButton(
          child: const Text("Enviar novo Modo"),
          onPressed: () {
            var url = Uri.http(
                selected!.ipaddress, "changeLED/${rgbMode.toString()}");
            http.get(url).then((value) => null).onError((error, stackTrace) {
              return null;
            });
          },
        ))
      ],
    );
  }

  Widget selectEspComponent(BuildContext context) {
    return esps.isNotEmpty
        ? DropdownButton(
            value: selected,
            items: esps,
            onChanged: (esp) {
              setState(() {
                selected = esp as Esp32;
              });
            })
        : const Text('');
  }

  Widget selectLEDColorComponent(BuildContext context) {
    return UnselectableElevatedButton(
      child: ElevatedButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: ((context) {
              var cor = selected == null ? selectedColor : selected!.cor;
              if (cor.blue == 0 && cor.red == 0 && cor.green == 0) {
                cor = Colors.pinkAccent;
              }
              return AlertDialog(
                titlePadding: const EdgeInsets.all(0),
                contentPadding: const EdgeInsets.all(0),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: cor,
                    onColorChanged: ((value) {
                      setState(() {
                        selectedColor = value;
                        selected?.cor = value;
                        /*colorTheme.add(
                          generateMaterialColor(color: value),
                        );*/
                      });
                    }),
                    portraitOnly: true,
                  ),
                ),
                actions: [
                  UnselectableTextButton(
                      child: TextButton(
                    child: const Text("Fechar"),
                    onPressed: () => Navigator.of(context).pop(),
                  )),
                ],
              );
            }),
          );
        },
        style: ButtonStyle(
            surfaceTintColor: MaterialStateProperty.all(
                (selected == null ? selectedColor : selected!.cor).alpha > 50
                    ? (selected == null ? selectedColor : selected!.cor)
                    : Theme.of(context).buttonTheme.colorScheme?.background)),
        child: const Text("Cor selecionada"),
      ),
    );
  }

  Widget sendFormButtonComponent(BuildContext context) {
    return UnselectableElevatedButton(
        child: ElevatedButton(
      onPressed: (() async {
        if (!formGlobalKey.currentState!.validate()) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Valor do brilho incorreto")));
          return;
        }
        if (selected == null ||
            selected!.ipaddress.isEmpty ||
            selectedMetodo.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Sem as informacoes todas")));
          return;
        }
        if (isFullWhite) {
          selectedColor = selectedColor
              .withRed(0)
              .withBlue(0)
              .withGreen(0)
              .withAlpha(0); //alpha a 0 porque inverte
        }
        var url = Uri.http(selected!.ipaddress,
            "mode/$selectedMetodo?r=${selectedColor.red},g=${selectedColor.green},b=${selectedColor.blue},w=${Esp32.map(selectedColor.alpha.toDouble(), 0, 255, 255, 0)},br=$brightnessVal");
        http.get(url).then((value) => null).onError((error, stackTrace) {
          return null;
        });
      }),
      child: const Text("Enviar"),
    ));
  }

  Widget selectLEDBrightnessComponent(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Text("Luminosidade:"),
        ),
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
        )
      ],
    );
  }

  Widget selectWhetherToUseWhiteComponent(BuildContext context) {
    return ListTile(
        title: const Text("Usar apenas branco"),
        leading: Switch(
          value: isFullWhite,
          onChanged: (value) => setState(() {
            isFullWhite = value;
          }),
        ));
  }

  Widget selectLightModeComponent(BuildContext context) {
    return DropdownButton(
      value: selected == null || selected!.modo.isEmpty
          ? selectedMetodo
          : selected!.modo,
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
            selected?.modo = val;
          });
        }
      },
    );
  }

  Widget waitTimeComponent(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: TextFormField(
            keyboardType: TextInputType.number,
            initialValue: selected == null
                ? waitTime.toString()
                : selected!.waitTime.toString(),
            onChanged: (value) {
              var aux = int.tryParse(value);
              if (aux != null && aux > 0) {
                setState(() {
                  waitTime = aux;
                  selected?.waitTime = aux;
                  isWaitButtonEnabled = true;
                });
              } else {
                setState(() {
                  isWaitButtonEnabled = false;
                });
              }
            },
          ),
        ),
        const SizedBox(
          width: 20,
        ),
        UnselectableOutlinedButton(
            child: OutlinedButton(
                onPressed: isWaitButtonEnabled
                    ? () {
                        var url =
                            Uri.http(selected!.ipaddress, "wait/$waitTime");
                        http
                            .get(url)
                            .then((value) => null)
                            .onError((error, stackTrace) {
                          return null;
                        });
                      }
                    : null,
                child: const Text('Definir tempo de espera'))),
      ],
    );
  }
}

enum RGBMode {
  grb,
  grbw;

  @override
  String toString() {
    switch (this) {
      case RGBMode.grb:
        return "RGB";
      case RGBMode.grbw:
        return "RGBW";
    }
  }

  RGBMode fromString(String s) {
    switch (s) {
      case "RGB":
        return RGBMode.grb;
      case "RGBW":
        return RGBMode.grbw;
    }
    throw Exception("Not valid String");
  }
}
