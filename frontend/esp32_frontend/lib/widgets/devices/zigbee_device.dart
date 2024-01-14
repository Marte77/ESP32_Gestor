// ignore_for_file: unnecessary_import

import 'dart:convert';
import 'dart:math';

import 'package:esp32_frontend/widgets/devices/devices/hue_929001821618/hue_929001821618.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';

import 'devices/tuya_ts0505b/tuya_ts0505b.dart';

class ZigBeeDevice extends StatefulWidget {
  const ZigBeeDevice(
      {Key? key,
      required this.appBar,
      required this.device,
      required this.mqttClient})
      : super(key: key);
  final AppBar appBar;
  final MqttClient? mqttClient;
  final Map<String, dynamic> device;
  static const String nullComponent = "NULO!_";

  /// param Y normalmente é a brightness
  // ignore: non_constant_identifier_names
  static Color convert_xyY_to_XYZ(double x, double y, double Y) {
    if (y == 0) return const Color.fromARGB(0, 0, 0, 0);
    //https://github.com/Shnoo/js-CIE-1931-rgb-color-converter/blob/master/ColorConverter.js#L211
    Y = Y / 255;
    double X = (Y / y) * x;
    double Z = (Y / y) * (1.0 - x - y);
    //usamos max para passar possiveis valores negativos a 0
    double r = max(
        reverseAndGammaCorrect(X * 1.656492 - Y * 0.354851 - Z * 0.255038), 0);
    double g = max(
        reverseAndGammaCorrect(-X * 0.707196 + Y * 1.655397 + Z * 0.036152), 0);
    double b = max(
        reverseAndGammaCorrect(X * 0.051713 - Y * 0.121364 + Z * 1.011530), 0);
    double maxOf3 = max3Numbers(r, g, b);
    if (maxOf3 > 1) {
      r = r / maxOf3;
      g = g / maxOf3;
      b = b / maxOf3;
    }
    return Color.fromARGB(
        255, (r * 255).floor(), (g * 255).floor(), (b * 255).floor());
  }

  static double max3Numbers(double a, double b, double c) {
    return max(max(a, b), c);
  }

  static double reverseAndGammaCorrect(double value) {
    return value <= 0.0031308
        ? 12.92 * value
        : (1.0 + 0.055) * pow(value, (1.0 / 2.4)) - 0.055;
  }

  @override
  State<ZigBeeDevice> createState() => _ZigBeeDeviceState();
}

class _ZigBeeDeviceState extends State<ZigBeeDevice> {
  String title = "",
      friendlyName = "",
      description = "",
      model = "",
      vendor = "",
      powerSource = "",
      ieeeAdress = "";
  late MqttClient mqttClient;
  Map<String, dynamic> payloadData = {};
  Map<String, dynamic> dataReceivedOnSubscribe = {};
  bool canRender = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      title = widget.device["friendly_name"];
      friendlyName = title;
      description = widget.device["description"];
      model = widget.device["model"];
      vendor = widget.device["vendor"];
      powerSource = widget.device["power_source"];
      ieeeAdress = widget.device["ieee_address"];
      mqttClient = widget.mqttClient!;
    });
    String topic = 'zigbee2mqtt/$friendlyName';
    var builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode({"state": ""}));
    mqttClient.subscribe(topic, MqttQos.atLeastOnce);
    mqttClient.publishMessage(
        '$topic/get', MqttQos.atMostOnce, builder.payload!);
    mqttClient.updates!.listen((event) {
      for (var evento in event) {
        if (evento.topic != topic) continue;
        var mensagem = (evento).payload as MqttPublishMessage;
        var conteudo =
            MqttPublishPayload.bytesToStringAsString(mensagem.payload.message);
        setState(() {
          canRender = true;
          dataReceivedOnSubscribe = jsonDecode(conteudo);
        });
        mqttClient.unsubscribe(topic);
      }
    });
  }

  Widget buildOptions() {
    Widget? lista;
    if (!canRender) return Container();
    //CADA DEVICE DEVE SUBSCREVER AO SEU RESPETIVO TOPICO.
    if (model.contains("TS0505B")) {
      //ligar e desligar
      lista = TuyaTS0505B(
          mqttClient: mqttClient,
          friendlyName: friendlyName,
          state: dataReceivedOnSubscribe,
          ieeeAddress: ieeeAdress);
    }
    if (model == "929001821618") {
      //ligar e desligar
      lista = Hue929001821618(
          mqttClient: mqttClient,
          friendlyName: friendlyName,
          state: dataReceivedOnSubscribe,
          ieeeAddress: ieeeAdress);
    }
    if (lista != null) {
      return lista;
    } else {
      return Container();
    }
  }

  ScrollController scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height -
          widget.appBar.preferredSize.height,
      width: MediaQuery.of(context).size.width,
      child: Card(
        //color: Colors.green[50],
        child: SingleChildScrollView(
            controller: scrollController,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 15),
                child: Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              Text(description),
              Text(model),
              Text(vendor),
              Text(powerSource),
              buildOptions(),
            ])),
      ),
    );
  }
}
