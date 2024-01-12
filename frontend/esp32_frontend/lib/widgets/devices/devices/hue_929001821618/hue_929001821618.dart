import 'dart:convert';

import 'package:esp32_frontend/util/mqtt_subscriber_interface.dart';
import 'package:esp32_frontend/widgets/devices/components/efeitos_dropdown.dart';
import 'package:esp32_frontend/widgets/devices/components/ligar_desligar.dart';
import 'package:esp32_frontend/widgets/devices/components/luminosidade.dart';
import 'package:esp32_frontend/widgets/devices/components/power_on_behaviour.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';

import '../../zigbee_device.dart';

class Hue929001821618 extends StatefulWidget {
  const Hue929001821618(
      {Key? key,
      required this.mqttClient,
      required this.state,
      required this.friendlyName})
      : super(key: key);
  final String friendlyName;
  final Map<String, dynamic> state;
  final MqttClient? mqttClient;
  @override
  State<Hue929001821618> createState() => _Hue929001821618State();
}

class _Hue929001821618State extends State<Hue929001821618>
    implements MQTTSubscriberInterface {
  late MqttClient mqttClient;
  Map<String, dynamic> payloadData = {
    "brightness": 254,
    "linkquality": 120,
    "power_on_behaviour": "off",
    "state": "OFF"
  };
  String topic = '';
  bool state = false;
  double brightness = 0;
  List<Text> effects = const [
    Text("----"),
    Text("Blink"),
    Text("Breathe"),
    Text("Okay"),
    Text("Channel Change"),
    Text("Finish Effect"),
    Text("Stop Effect"),
    Text("Stop Hue Effect"),
  ];
  String effectChosen = "----";
  String powerOnBehaviour = "";
  List<bool> powerOnBehaviourBool = [true, false, false, false];
  List<String> powerOnBehaviourValues = ["off", "on", "toggle", "previous"];

  void setData() {
    state = payloadData["state"] == "ON" ? true : false;
    brightness = payloadData["brightness"] != null
        ? (payloadData["brightness"] as int).toDouble()
        : 0;
    powerOnBehaviour =
        payloadData["power_on_behavior"] ?? ZigBeeDevice.nullComponent;
  }

  @override
  initState() {
    super.initState();
    mqttClient = widget.mqttClient!;
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

  List<Widget> elementos(BuildContext context) {
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
      EfeitosDropdown(
          list: effects,
          onChanged: (value) {
            setState(() {
              effectChosen = value;
            });
            if (effectChosen != effects.first.data!) {
              publishChanges(
                  {"effect": effectChosen.toLowerCase().replaceAll(' ', '_')});
            }
          }),
      const Divider(),
      if (powerOnBehaviour != ZigBeeDevice.nullComponent)
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
      stream: mqttClient.updates!,
      builder: (context, snapshot) {
        //nao preciso de fazer nada pois no initState já tenho a funcao a fazer listen
        return Column(children: elementos(context));
      },
    );
  }

  @override
  void subscribeToTopic() {
    mqttClient.subscribe(topic, MqttQos.atLeastOnce);
  }

  @override
  void publishChanges(Map<String, dynamic> map) {
    subscribeToTopic();
    var builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(map));
    mqttClient.publishMessage(
        '$topic/set', MqttQos.atMostOnce, builder.payload!);
  }

  @override
  void unsubscribeToTopic() {
    mqttClient.unsubscribe(topic);
  }

  @override
  void dispose() {
    super.dispose();
    unsubscribeToTopic();
  }
}
