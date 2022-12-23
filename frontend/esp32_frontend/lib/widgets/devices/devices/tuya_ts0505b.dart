import 'dart:convert';

import 'package:esp32_frontend/util/mqtt_subscriber_interface.dart';
import 'package:esp32_frontend/widgets/devices/components/color_temp_with_preset.dart';
import 'package:esp32_frontend/widgets/devices/components/efeitos_dropdown.dart';
import 'package:esp32_frontend/widgets/devices/components/escolher_cor.dart';
import 'package:esp32_frontend/widgets/devices/components/ligar_desligar.dart';
import 'package:esp32_frontend/widgets/devices/components/luminosidade.dart';
import 'package:esp32_frontend/widgets/devices/components/power_on_behaviour.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../ziggbee_device.dart';

class TuyaTS0505B extends StatefulWidget {
  const TuyaTS0505B(
      {Key? key,
      required this.mqttClient,
      required this.state,
      required this.friendlyName})
      : super(key: key);
  final String friendlyName;
  final Map<String, dynamic> state;
  final MqttServerClient mqttClient;
  @override
  State<TuyaTS0505B> createState() => _TuyaTS0505BState();
}

class _TuyaTS0505BState extends State<TuyaTS0505B>
    implements MQTTSubscriberInterface {
  Map<String, dynamic> payloadData = {
    "brightness": 254,
    "color": {
      "hue": 32,
      "saturation": 82,
      "x": 0.4599,
      "y": 0.4106,
    },
    "color_mode": "color_temp",
    "color_temp": 143,
    "linkquality": 120,
    "power_on_behaviour": "off",
    "state": "OFF"
  };
  String topic = '';
  bool state = false;
  // ignore: non_constant_identifier_names
  double brightness = 0, color_temp = 153;
  final colorTempTemplates = [false, false, false, false, false];
  Color selectedColor = Colors.pink;
  List<Text> effects = const [
    Text("----"),
    Text("Blink"),
    Text("Breathe"),
    Text("Okay"),
    Text("Channel Change"),
    Text("Finish Effect"),
    Text("Stop Effect")
  ];
  String effectChosen = "----";
  String powerOnBehaviour = "";
  List<bool> powerOnBehaviourBool = [true, false, false, false];
  List<String> powerOnBehaviourValues = ["off", "on", "toggle", "previous"];

  void setData() {
    state = payloadData["state"] == "ON" ? true : false;
    brightness = (payloadData["brightness"] as int).toDouble();
    selectedColor = ZigBeeDevice.convert_xyY_to_XYZ(
        payloadData["color"]["x"],
        payloadData["color"]["y"],
        100); //((payloadData["color"]["saturation"]) as int).toDouble());
    color_temp = (payloadData["color_temp"] as int).toDouble();
    powerOnBehaviour = payloadData["power_on_behavior"];
  }

  @override
  initState() {
    super.initState();
    setState(() {
      topic = 'zigbee2mqtt/${widget.friendlyName}';
      payloadData = widget.state;
      setData();
    });
    var sub = widget.mqttClient.subscribe(topic, MqttQos.atMostOnce);
    if (sub == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Erro a subscrever")));
    }
    widget.mqttClient.updates!.listen((event) {
      for (var evento in event) {
        if (evento.topic == topic) {
          payloadData = jsonDecode(MqttPublishPayload.bytesToStringAsString(
              (evento.payload as MqttPublishMessage).payload.message));
          setData();
        }
      }
    });
  }

  List<Widget> elementos(BuildContext context) {
    // ignore: prefer_function_declarations_over_variables
    void Function() sendColorTemp = () {
      publishChanges({"color_temp": color_temp.round()});
    };
    // ignore: prefer_function_declarations_over_variables
    void Function() sendNewColor = () {
      publishChanges({
        "color": {
          "rgb":
              "${selectedColor.red},${selectedColor.green},${selectedColor.blue}"
        }
      });
      payloadData["color_mode"] = "xy";
    };
    return [
      LigarDesligar(
          state: state,
          onChanged: (value) {
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
      const Divider(),
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
      const Divider(),
      ColorTempWithPreset(
          colorTempTemplatesBool: colorTempTemplates,
          colorTempTemplatesNames: const [
            Text("Coolest"),
            Text("Cool"),
            Text("Neutral"),
            Text("Warm"),
            Text("Warmest"),
          ],
          min: 153,
          max: 500,
          value: color_temp,
          onPressed: ((index) {
            for (var i = 0; i < colorTempTemplates.length; i++) {
              colorTempTemplates[i] = false;
            }
            colorTempTemplates[index] = true;
            setState(() {
              switch (index) {
                case 0:
                  color_temp = 153;
                  break;
                case 1:
                  color_temp = 250;
                  break;
                case 2:
                  color_temp = 370;
                  break;
                case 3:
                  color_temp = 454;
                  break;
                case 4:
                  color_temp = 500;
                  break;
              }
              payloadData["color_temp"] = color_temp.round();

              sendColorTemp();
            });
          }),
          onChangeEnd: ((value) {
            setState(() {
              color_temp = value;
              payloadData["color_temp"] = color_temp.round();
              sendColorTemp();
              payloadData["color_mode"] = "color_temp";
            });
          })),
      const Divider(),
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
      const Divider(),
      EfeitosDropdown(
          list: effects,
          onChanged: (value) {
            setState(() {
              effectChosen = value;
            });
            if (effectChosen != effects.first.data!) {
              publishChanges(
                  {"effect": effectChosen.toLowerCase().replaceAll(' ', '_')});
            } else {
              if (payloadData["color_mode"] == "xy") {
                sendNewColor();
              } else {
                sendColorTemp();
              }
            }
          }),
      const Divider(),
      PowerOnBehaviourToggle(
        toggleList: const [
          Text("Off"),
          Text("On"),
          Text("Toggle"),
          Text("Previous"),
        ],
        alreadySelected: powerOnBehaviour,
        onPressed: ((value) {
          setState(() {
            powerOnBehaviour = value;
            payloadData["power_on_behaviour"] = value;
          });
          publishChanges({"power_on_behavior": value.toLowerCase()});
        }),
      )
    ];
  }

  ScrollController scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MqttReceivedMessage<MqttMessage>>>(
      stream: widget.mqttClient.updates!,
      builder: (context, snapshot) {
        //nao preciso de fazer nada pois no initState já tenho a funcao a fazer listen
        return Column(children: elementos(context));
      },
    );
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
  }
}
