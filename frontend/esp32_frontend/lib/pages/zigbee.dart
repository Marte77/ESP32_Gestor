import 'dart:convert';

import 'package:esp32_frontend/util/support_web_mobile/mqtt_finder.dart';
import 'package:esp32_frontend/widgets/devices/zigbee_device.dart';
import 'package:esp32_frontend/widgets/other/navdrawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';

class PaginaZigbee extends StatefulWidget {
  const PaginaZigbee({Key? key}) : super(key: key);

  @override
  State<PaginaZigbee> createState() => _PaginaZigbeeState();
}

class _PaginaZigbeeState extends State<PaginaZigbee> {
  final mqttClient = MqttFinder().getClient();
  bool willRenderNormal = true;
  static const zigbee2mqttTopic = 'zigbee2mqtt/bridge/devices';
  List<Map<String, dynamic>> listaDevices = [];
  int deviceCardIndex = 0;
  final PageController scrollBarCardController = PageController(initialPage: 0);
  @override
  void initState() {
    super.initState();
    mqttClient.logging(on: false);
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
      setState(() {
        willRenderNormal = false;
      });
    }).then((value) {
      if (mqttClient.connectionStatus?.state == MqttConnectionState.connected) {
        mqttClient.subscribe(zigbee2mqttTopic, MqttQos.atLeastOnce);
        mqttClient.updates!.listen((event) => parseDevices(event));
      }
    });
    mqttClient.onConnected = mqttOnConnected;
  }

  void parseDevices(List<MqttReceivedMessage<MqttMessage>> data) {
    if (data.length == 1 && data.first.topic == zigbee2mqttTopic) {
      //vai ter todos os devices da rede
      String conteudo = MqttPublishPayload.bytesToStringAsString(
          (data.first.payload as MqttPublishMessage).payload.message);
      listaDevices.clear();
      List devices = jsonDecode(conteudo);

      for (var element in devices) {
        if (element["type"] as String != 'Coordinator') {
          listaDevices.add({
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
      setState(() {});
    }
  }

  void mqttOnConnected() {}

  @override
  void dispose() {
    mqttClient.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var myAppBar = AppBar(
      title: const Text("ZigBee"),
    );
    return Scaffold(
      appBar: myAppBar,
      drawer: const NavDrawer(),
      body: Center(
          child: willRenderNormal
              ? Column(
                  children: [
                    Expanded(
                        child: Scrollbar(
                      controller: scrollBarCardController,
                      thumbVisibility: true,
                      child: ListView.builder(
                          itemCount: listaDevices.length,
                          controller: scrollBarCardController,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return ZigBeeDevice(
                              appBar: myAppBar,
                              mqttClient: mqttClient,
                              device: listaDevices.elementAt(index),
                            );
                          }),
                    ))
                    /*ElevatedButton(
                        onPressed: () {
                          var builder = MqttClientPayloadBuilder();
                          builder.addString('{"state":"OFF"}');
                          mqttClient.publishMessage(
                              'zigbee2mqtt/primeira lampada aliexpress/set',
                              MqttQos.atLeastOnce,
                              builder.payload!);
                          builder.addString('[{"state":"ON"}]');
                          mqttClient.publishMessage(
                              'zigbee2mqtt/bridge/devices',
                              MqttQos.atLeastOnce,
                              builder.payload!);
                        },
                        child: const Text("enviar"))*/
                  ],
                )
              : null),
    );
  }
}
