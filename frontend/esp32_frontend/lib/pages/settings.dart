import 'package:esp32_frontend/main.dart';
import 'package:esp32_frontend/util/string_extension.dart';
import 'package:esp32_frontend/util/support_web_mobile/impl/mobile_finder.dart';
import 'package:esp32_frontend/widgets/other/my_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String serverIp = '', serverPort = '';
  @override
  void initState() {
    super.initState();
    initAsync();
  }
  void initAsync() async {
    var sp = await SharedPreferences.getInstance();
    setState(() {
      serverIp = sp.getString(SHARED_PREFS_SERVER_KEY)!;
      serverPort = sp.getString(SHARED_PREFS_SERVER_PORT_KEY)!;
      print("$serverIp:$serverPort");
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Definições"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(children: [
        TextButton(
            onPressed: () {
              var cor = const Color.fromARGB(255, 255, 0, 136);
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      titlePadding: const EdgeInsets.all(0),
                      contentPadding: const EdgeInsets.all(0),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: cor,
                          onColorChanged: ((value) {
                            cor = value;
                          }),
                          portraitOnly: true,
                        ),
                      ),
                      actions: [
                        UnselectableTextButton(
                            child: TextButton(
                          child: const Text("Fechar"),
                          onPressed: () {
                            //MyApp.notifier.value = MyApp.notifier.value
                            //    .copyWith(
                            //        colorScheme:
                            //            ColorScheme.fromSeed(seedColor: cor));
                            Navigator.of(context).pop();
                          },
                        )),
                      ],
                    );
                  });
            },
            child: const Text("azul")),
        TextButton(
            onPressed: () {
              MyApp.notifier.value = MyApp.notifier.value
                  .copyWith(splashFactory: InkSplash.splashFactory);
            },
            child: const Text("InkSplash")),
        TextButton(
            onPressed: () {
              MyApp.notifier.value = MyApp.notifier.value
                  .copyWith(splashFactory: InkRipple.splashFactory);
            },
            child: const Text("InkRipple")),
        TextButton(
            onPressed: () {
              if (!kIsWeb) {
                MyApp.notifier.value = MyApp.notifier.value
                    .copyWith(splashFactory: InkSparkle.splashFactory);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Web nao suporta InkSparkle")));
              }
            },
            child: const Text("InkSparkle")),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                onChanged: (changed) {
                  setState(() {
                    serverIp = changed;
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Server IP',
                ),
                initialValue: serverIp,

              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Server Port for ESP32',
                ),
                  initialValue: serverPort,
                  onChanged: (changed) {
                  setState(() {
                    serverPort = changed;
                  });
                },
              ),
            ),
            ElevatedButton(onPressed: () async {
              (await SharedPreferences.getInstance())
                  ..setString(SHARED_PREFS_SERVER_PORT_KEY, serverPort)
                  ..setString(SHARED_PREFS_SERVER_KEY, serverIp);
            }, child: const Text("Submeter"))
          ],
        )
      ]),
    );
  }
}
