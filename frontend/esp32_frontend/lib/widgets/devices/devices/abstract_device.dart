import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../../../globals.dart';
import '../../../util/mqtt_subscriber_interface.dart';
import '../components/color_temp_with_preset.dart';
import '../components/efeitos_dropdown.dart';
import '../components/escolher_cor.dart';
import '../components/ligar_desligar.dart';
import '../components/luminosidade.dart';
import '../components/power_on_behaviour.dart';
import '../zigbee_device.dart';
import "package:esp32_frontend/globals.dart" as globals;

abstract class AbstractDevice extends StatefulWidget {
  const AbstractDevice(
      {Key? key,
      required this.ieeeAddress,
      required this.state,
      required this.friendlyName})
      : super(key: key);
  final String friendlyName;
  final String ieeeAddress;
  final Map<String, dynamic> state;
}

enum DeviceProperties {
  brightness("brightness"),
  color("color", isComplex: true),
  colorMode("color_mode"),
  colorTemp("color_temp"),
  powerOnBehaviour("power_on_behaviour"),
  state("state"),
  effects("effect");

  const DeviceProperties(
    this.value, {
    this.isComplex = false,
  });
  final bool isComplex;
  final String value;
}

abstract class AbstractDeviceState<T extends AbstractDevice> extends State<T>
    implements MQTTSubscriberInterface {
  abstract List<DeviceProperties> deviceProperties;
  set _deviceProperties(List<DeviceProperties> list) {
    deviceProperties = list;
  }

  Map<String, dynamic> payloadData = {};
  /* = {
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
  };*/
  bool state = false;
  late String topic;
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
    if (deviceProperties.contains(DeviceProperties.state)) {
      state = payloadData["state"] == "ON" ? true : false;
    }

    if (deviceProperties.contains(DeviceProperties.brightness)) {
      brightness = payloadData["brightness"] != null
          ? (payloadData["brightness"] as int).toDouble()
          : 0;
    }

    if (deviceProperties.contains(DeviceProperties.effects)) {
      if (payloadData["effect"] != null) {
        var list = payloadData["effect"] as List<String>;
        var listtext = <Text>[];
        for (var str in list) {
          listtext.add(Text(str));
        }
        effects = listtext;
      } else {
        effects = [];
      }
    }

    if (deviceProperties.contains(DeviceProperties.color)) {
      selectedColor = payloadData["color"] != null
          ? ZigBeeDevice.convert_xyY_to_XYZ(
              payloadData["color"]["x"], payloadData["color"]["y"], 100)
          : Colors.pink;
    }

    if (deviceProperties.contains(DeviceProperties.colorTemp)) {
      color_temp = payloadData["color_temp"] != null
          ? (payloadData["color_temp"] as int).toDouble()
          : 0;
    }

    if (deviceProperties.contains(DeviceProperties.powerOnBehaviour)) {
      powerOnBehaviour =
          payloadData["power_on_behavior"] ?? ZigBeeDevice.nullComponent;
    }
  }

  /* ------------- METODOS DO FLUTTER ------------- */

  @override
  void initState() {
    super.initState();
    var mqttClient = globals.mqttClient!;
    setState(() {
      topic = 'zigbee2mqtt/${widget.friendlyName}';
      payloadData = widget.state;
      setData();
    });
    var sub = mqttClient.subscribe(topic, MqttQos.atMostOnce);
    if (sub == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Erro a subscrever")));
    }
    mqttClient.updates!.listen((event) {
      for (var evento in event) {
        if (evento.topic == topic) {
          payloadData = jsonDecode(MqttPublishPayload.bytesToStringAsString(
              (evento.payload as MqttPublishMessage).payload.message));
          setData();
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    unsubscribeToTopic();
  }

  ScrollController scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MqttReceivedMessage<MqttMessage>>>(
      stream: mqttClient!.updates!,
      builder: (context, snapshot) {
        //nao preciso de fazer nada pois no initState já tenho a funcao a fazer listen
        return Column(children: elementos(context));
      },
    );
  }

  /* ------------- METODOS DA INTERFACE MQTTLISTENER ------------- */

  @override
  void subscribeToTopic() {
    mqttClient!.subscribe(topic, MqttQos.atLeastOnce);
  }

  @override
  void publishChanges(Map<String, dynamic> map) {
    subscribeToTopic();
    var builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(map));
    mqttClient!.publishMessage(
        '$topic/set', MqttQos.atMostOnce, builder.payload!);
  }

  @override
  void unsubscribeToTopic() {
    mqttClient!.unsubscribe(topic);
  }

  /* ------------- METODOS DE WIDGETS ------------- */

  List<Widget> elementos(BuildContext context) {
    List<Widget> list = [];
    addTurnOnOffWidget(list, context);
    addBrightnessWidget(list, context);
    addColorTemperatureWidget(list, context);
    addColorChangeWidget(list, context);
    addEffectsWidget(list, context);
    addPowerOnBehaviourWidget(list, context);
    if (list.last is Divider) {
      list.removeLast();
    }
    return list;
  }

  void addTurnOnOffWidget(List<Widget> list, BuildContext context) {
    if (deviceProperties.contains(DeviceProperties.state)) {
      list.add(LigarDesligar(
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
          }));
      list.add(const Divider());
    }
  }

  void addBrightnessWidget(List<Widget> list, BuildContext context) {
    if (deviceProperties.contains(DeviceProperties.brightness)) {
      list.add(LuminosidadeSlider(
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
      ));
      list.add(const Divider());
    }
  }

  void addColorTemperatureWidget(List<Widget> list, BuildContext context) {
    if (deviceProperties.contains(DeviceProperties.colorTemp)) {
      list.add(ColorTempWithPreset(
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
          })));
      list.add(const Divider());
    }
  }

  void addColorChangeWidget(List<Widget> list, BuildContext context) {
    if (deviceProperties.contains(DeviceProperties.color)) {
      list.add(EscolherCor(
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
      ));
      list.add(const Divider());
    }
  }

  void addEffectsWidget(List<Widget> list, BuildContext context) {
    if (deviceProperties.contains(DeviceProperties.effects)) {
      list.add(EfeitosDropdown(
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
          }));
      list.add(const Divider());
    }
  }

  void addPowerOnBehaviourWidget(List<Widget> list, BuildContext context) {
    if (deviceProperties.contains(DeviceProperties.powerOnBehaviour) &&
        powerOnBehaviour != ZigBeeDevice.nullComponent) {
      list.add(PowerOnBehaviourToggle(
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
      ));
      list.add(const Divider());
    }
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

  void sendColorTemp() {
    publishChanges({"color_temp": color_temp.round()});
  }
}
