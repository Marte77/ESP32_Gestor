import 'dart:convert';

import 'package:esp32_frontend/util/mqtt_subscriber_interface.dart';
import 'package:esp32_frontend/widgets/devices/components/escolher_cor.dart';
import 'package:esp32_frontend/widgets/devices/components/ligar_desligar.dart';
import 'package:esp32_frontend/widgets/devices/components/luminosidade.dart';
import 'package:esp32_frontend/widgets/devices/devices/abstract_device.dart';
import 'package:esp32_frontend/widgets/devices/zigbee_device.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';

abstract class AbstractDeviceMainCard extends StatefulWidget {
  const AbstractDeviceMainCard(
      {Key? key,
      required this.mqttClient,
      required this.friendlyName,
      required this.state,
      required this.ieeeAddress})
      : super(key: key);
  final MqttClient mqttClient;
  final String friendlyName;
  final String ieeeAddress;
  final Map<String, dynamic> state;
}

abstract class AbstractDeviceMainCardState<T extends AbstractDeviceMainCard>
    extends State<T> implements MQTTSubscriberInterface {
  bool state = false, canRender = false;
  double brightness = 0;
  String topic = '';
  Map<String, dynamic> payloadData = {};
  Color selectedColor = Colors.pink;
  abstract List<DeviceProperties> deviceProperties;
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
    selectedColor = payloadData["color"] != null
        ? ZigBeeDevice.convert_xyY_to_XYZ(
            payloadData["color"]["x"], payloadData["color"]["y"], 100)
        : Colors.pink;
  }

  void sendNewColor() {
    publishChanges({
      "color": {
        "rgb":
            "${selectedColor.red},${selectedColor.green},${selectedColor.blue}"
      }
    });
    payloadData["color_mode"] = "xy";
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
                if (deviceProperties.contains(DeviceProperties.state))
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
                if (deviceProperties.contains(DeviceProperties.brightness))
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
                if (deviceProperties.contains(DeviceProperties.color))
                  EscolherCor(
                    onChangeColor: (value) {},
                    color: selectedColor,
                    context: context,
                    onClosePopup: (chosenColor) {
                      selectedColor = chosenColor;
                      payloadData["color"] = {
                        "hex": "#${selectedColor.value.toRadixString(16)}"
                      };
                      sendNewColor();
                    },
                  ),
              ]),
            ),
          )
        : const Card();
  }

  @override
  void dispose() {
    super.dispose();
    unsubscribeToTopic();
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
