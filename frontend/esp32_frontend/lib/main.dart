import 'dart:async';
import 'dart:convert';
import 'package:esp32_frontend/pages/esp32.dart';
import 'package:esp32_frontend/pages/zigbee.dart';
import 'package:esp32_frontend/util/support_web_mobile/mqtt_finder.dart';
import 'package:esp32_frontend/widgets/devices/devices/esp32/esp32_main_card.dart';
import 'package:esp32_frontend/widgets/devices/devices/tuya_ts0505b/tuya_ts0505b_main_card.dart';
import 'package:esp32_frontend/widgets/other/my_button.dart';
import 'package:esp32_frontend/widgets/other/navdrawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_color_generator/material_color_generator.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:http/http.dart' as http;

StreamController<MaterialColor> colorTheme = StreamController();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MaterialColor>(
      initialData: Colors.pink,
      stream: colorTheme.stream,
      builder: ((context, snapshot) {
        MaterialColor? data = snapshot.data;
        if (snapshot.hasData) {
          if (snapshot.data!.alpha != 255) {
            data = generateMaterialColor(
                color: snapshot.data!.withOpacity(1).withAlpha(255));
          }
        }
        return MaterialApp(
          title: 'Mudar Leds',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: data ?? Colors.pink,
            splashFactory: InkRipple.splashFactory,
            sliderTheme: const SliderThemeData(
              showValueIndicator: ShowValueIndicator.always,
            ),
          ),
          routes: {
            '/': (context) => const MyHomePage(title: "Pagina inicial"),
            '/esp32': (context) => const PaginaEsp32(),
            '/zigbee': (context) => const PaginaZigbee()
          },
          onUnknownRoute: (RouteSettings settings) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (BuildContext context) => Scaffold(
                body: UnselectableElevatedButton(
                    child: ElevatedButton(
                        onPressed: () => Navigator.popUntil(
                            context, (route) => route.isFirst),
                        child: const Text('Not Found'))),
              ),
            );
          },
        );
      }),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final mqttClient = MqttFinder().getClient();
  List<Map<String, dynamic>> listaDevicesMqtt = [];
  static const zigbee2mqttTopic = 'zigbee2mqtt/bridge/devices';
  List<Widget> cards = [];
  List<Esp32> esps = [];
  @override
  void initState() {
    super.initState();
    final connMess = MqttConnectMessage()
        .withClientIdentifier('Mqtt_MyClientUniqueId')
        .withWillTopic(
            'willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);
    mqttClient.connectionMessage = connMess;
    mqttClient.autoReconnect = true;
    mqttClient.connect().catchError((e) {
      if (kDebugMode) {
        print(e);
      }
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro a conectar tenta mais tarde")));
      return e;
    }).then((value) {
      if (mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
        mqttClient.subscribe(zigbee2mqttTopic, MqttQos.atLeastOnce);
        mqttClient.updates!.listen((event) => parseDevices(event));
      }
    });
    initAsync();
  }

  void initAsync() async {
    var url = Uri.http('192.168.3.0:8080', 'getall');
    var res = await http.get(url);
    if (res.statusCode == 200) {
      List<dynamic> parsed = jsonDecode(res.body)['dados'];
      for (var esp in parsed) {
        List<String> cores = (esp['cor']! as String)
            .replaceAll("(", "")
            .replaceAll(")", "")
            .split(",");
        esps.add(
          Esp32(
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
        );
      }
      createCardsEsp();
    }
  }

  void createCardsEsp() {
    for (var esp in esps) {
      cards.add(Esp32MainCard(esp32: esp));
    }
    setState(() {});
  }

  void parseDevices(List<MqttReceivedMessage<MqttMessage>> data) {
    listaDevicesMqtt.clear();
    if (data.length == 1 && data.first.topic == zigbee2mqttTopic) {
      //vai ter todos os devices da rede
      String conteudo = MqttPublishPayload.bytesToStringAsString(
          (data.first.payload as MqttPublishMessage).payload.message);
      listaDevicesMqtt.clear();
      List devices = jsonDecode(conteudo);

      for (var element in devices) {
        if (element["type"] as String != 'Coordinator') {
          listaDevicesMqtt.add({
            "name": element["definition"],
            "friendly_name": element["friendly_name"],
            "exposes": element["definition"]["exposes"],
            "model": element["definition"]["model"],
            "vendor": element["definition"]["vendor"],
            "description": element["definition"]["description"],
            "power_source": element["power_source"],
            "ieee_address": element["ieee_address"]
          });
        }
      }
      createCardsZig();
      setState(() {});
    }
  }

  void createCardsZig() {
    if (mqttClient.connectionStatus == null ||
        (mqttClient.connectionStatus!.state ==
                MqttConnectionState.disconnected ||
            mqttClient.connectionStatus!.state ==
                MqttConnectionState.disconnecting)) {
      while (mqttClient.connectionStatus!.state ==
          MqttConnectionState.disconnecting) {}
      final connMess = MqttConnectMessage()
          .withClientIdentifier('Mqtt_MyClientUniqueId')
          .withWillTopic(
              'willtopic') // If you set this you must set a will message
          .withWillMessage('My Will message')
          .startClean() // Non persistent session for testing
          .withWillQos(MqttQos.atLeastOnce);
      mqttClient.connectionMessage = connMess;
      mqttClient.connect().catchError((e) {
        if (kDebugMode) {
          print(e);
        }
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erro a conectar tenta mais tarde")));
      });
    }
    for (var zig in listaDevicesMqtt) {
      if (zig["model"] == "TS0505B") {
        cards.add(TuyaTS0505bMainCard(
            mqttClient: mqttClient,
            friendlyName: zig["friendly_name"],
            state: zig));
      }
    }
  }

  @override
  void dispose() {
    mqttClient.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
      ),
      drawer: const NavDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
              image: AssetImage('assets/images/pizza.jpg'), fit: BoxFit.fill),
        ),
        child: SingleChildScrollView(
            child: SelectionArea(child: Column(children: cards))),
      ),
    );
  }
}
