import 'dart:convert';
import 'package:esp32_frontend/pages/esp32.dart';
import 'package:esp32_frontend/pages/settings.dart';
import 'package:esp32_frontend/pages/zigbee.dart';
import 'package:esp32_frontend/util/string_extension.dart';
import 'package:esp32_frontend/util/support_web_mobile/mqtt_finder.dart';
import 'package:esp32_frontend/widgets/devices/devices/abstract_device_main_card.dart';
import 'package:esp32_frontend/widgets/devices/devices/esp32/esp32_main_card.dart';
import 'package:esp32_frontend/widgets/devices/devices/hue_929001821618/hue_929001821618_main_card.dart';
import 'package:esp32_frontend/widgets/devices/devices/tuya_ts0505b/tuya_ts0505b_main_card.dart';
import 'package:esp32_frontend/widgets/other/my_button.dart';
import 'package:esp32_frontend/widgets/other/navdrawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'globals.dart' as globals;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var sp = await SharedPreferences.getInstance();
  if (!sp.containsKey("server")) {
    sp.setString(SHARED_PREFS_SERVER_KEY, "192.168.0.103");
    sp.setString(SHARED_PREFS_SERVER_PORT_KEY, "8081");
  }
  globals.mqttClient = MqttFinder().getClient();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  static final ValueNotifier<ThemeData> notifier = ValueNotifier(
    ThemeData(
      colorSchemeSeed: const Color.fromARGB(255, 255, 0, 0),
      splashFactory: InkSparkle.splashFactory,//InkRipple.splashFactory,
      sliderTheme: const SliderThemeData(
        showValueIndicator: ShowValueIndicator.always,
      ),
      brightness: WidgetsBinding.instance.platformDispatcher.platformBrightness,
    ),
  );
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: notifier,
        builder: (context, themeData, widget) {
          var themeMode = themeData.brightness == Brightness.light
              ? ThemeMode.light
              : ThemeMode.dark;
          return widget ??
              MaterialApp(
                title: 'Mudar Leds',
                debugShowCheckedModeBanner: false,
                themeMode: themeMode,
                theme: themeData.copyWith(brightness: Brightness.light),
                darkTheme: themeData.copyWith(brightness: Brightness.dark),
                routes: {
                  '/': (context) => const MyHomePage(title: "Pagina inicial"),
                  '/esp32': (context) => const PaginaEsp32(),
                  '/zigbee': (context) => const PaginaZigbee(),
                  '/settings': (context) => const SettingsPage()
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
        });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
    var mqttClient = globals.mqttClient!;
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
        if (kDebugMode) {
          print("MAIN::MQTT Connected");
        }
        mqttClient.subscribe(zigbee2mqttTopic, MqttQos.atLeastOnce);
        mqttClient.updates!.listen((event) => parseDevices(event));
      }
    });
    initAsync();
  }

  void initAsync() async {
    var url = Uri.http('192.168.0.103:8081', 'getall');
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
    var mqttClient = globals.mqttClient!;
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
      String ieeeAddress = zig["ieee_address"];
      var existe = cards.indexWhere((element) =>
          element is AbstractDeviceMainCard &&
          element.ieeeAddress == ieeeAddress);
      if (existe != -1) continue;
      if (zig["model"].contains("TS0505B")) {
        cards.add(TuyaTS0505bMainCard(
            friendlyName: zig["friendly_name"],
            ieeeAddress: ieeeAddress,
            state: zig));
      }
      if (zig["model"] == "929001821618") {
        //ligar e desligar
        cards.add(Hue929001821618MainCard(
            friendlyName: zig["friendly_name"],
            ieeeAddress: ieeeAddress,
            state: zig));
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inicio"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
                onPressed: () => Navigator.pushNamed(context, "/settings"),
                icon: const Icon(Icons.settings)),
          )
        ],
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
