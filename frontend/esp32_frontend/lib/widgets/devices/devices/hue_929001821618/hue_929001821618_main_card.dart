import 'dart:convert';

import 'package:esp32_frontend/util/mqtt_subscriber_interface.dart';
import 'package:esp32_frontend/widgets/devices/components/ligar_desligar.dart';
import 'package:esp32_frontend/widgets/devices/components/luminosidade.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';

class Hue929001821618MainCard extends StatefulWidget {
  const Hue929001821618MainCard(
      {Key? key,
      required this.mqttClient,
      required this.friendlyName,
      required this.state})
      : super(key: key);
  final MqttClient mqttClient;
  final String friendlyName;
  final Map<String, dynamic> state;

  @override
  State<Hue929001821618MainCard> createState() =>
      _Hue929001821618MainCardState();
}

class _Hue929001821618MainCardState extends State<Hue929001821618MainCard>
    implements MQTTSubscriberInterface {
  bool state = false, canRender = false;
  double brightness = 0;
  String topic = '';
  Map<String, dynamic> payloadData = {};
  Color selectedColor = Colors.pink;
  @override
  void initState() {
    super.initState();

    topic = 'zigbee2mqtt/${widget.friendlyName}';
    payloadData = widget.state;
    subscribeToTopic();
    widget.mqttClient.updates!.listen((event) {
      for (var evento in event) {
        if (evento.topic == topic) {
          payloadData = jsonDecode(MqttPublishPayload.bytesToStringAsString(
              (evento.payload as MqttPublishMessage).payload.message));
          setState(() {
            canRender = true;
            setData();
          });
        }
      }
    });
    var builder = MqttClientPayloadBuilder();
    builder.addString('{"state": ""}');
    widget.mqttClient
        .publishMessage("$topic/get", MqttQos.atLeastOnce, builder.payload!);
  }

  void setData() {
    state = payloadData["state"] == "ON" ? true : false;
    brightness = payloadData["brightness"] != null
        ? (payloadData["brightness"] as int).toDouble()
        : 0;
  }

  @override
  void dispose() {
    super.dispose();
    unsubscribeToTopic();
  }

  @override
  Widget build(BuildContext context) {
    return canRender
        ? Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: Column(children: [
                Text(
                  "Dispositivo: ${widget.friendlyName}\n\nModelo:${widget.state["model"]}",
                  textAlign: TextAlign.center,
                ),
                LigarDesligar(
                    onChanged: ((value) {
                      setState(() {
                        if (value) {
                          state = true;
                          payloadData["state"] = "ON";
                        } else if (!value) {
                          state = false;
                          payloadData["state"] = "OFF";
                        }
                      });
                      publishChanges({"state": payloadData["state"]});
                    }),
                    state: state),
                LuminosidadeSlider(
                  brightness: brightness,
                  min: 0,
                  max: 254,
                  onChangeEnd: (value) {
                    setState(() {
                      brightness = value;
                      payloadData["brightness"] = brightness.round();
                    });
                    publishChanges({"brightness": brightness.round()});
                  },
                ),
              ]),
            ),
          )
        : const Card();
  }

  @override
  void subscribeToTopic() {
    widget.mqttClient.subscribe(topic, MqttQos.atLeastOnce);
  }

  @override
  void publishChanges(Map<String, dynamic> map) {
    subscribeToTopic();
    var builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(map));
    widget.mqttClient
        .publishMessage('$topic/set', MqttQos.atMostOnce, builder.payload!);
    setState(() {});
  }

  @override
  void unsubscribeToTopic() {
    widget.mqttClient.unsubscribe(topic);
  }
}
