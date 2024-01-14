import 'package:esp32_frontend/widgets/devices/devices/abstract_device.dart';
import 'package:flutter/material.dart';

class TuyaTS0505B extends AbstractDevice {
  const TuyaTS0505B(
      {super.key,
      required super.mqttClient,
      required super.state,
      required super.friendlyName,
      required super.ieeeAddress});

  @override
  State<TuyaTS0505B> createState() => _TuyaTS0505BState();
  static final List<DeviceProperties> tuyaTS0505BProperties = [
    DeviceProperties.brightness,
    DeviceProperties.color,
    DeviceProperties.colorMode,
    DeviceProperties.colorTemp,
    DeviceProperties.powerOnBehaviour,
    DeviceProperties.state,
    DeviceProperties.effects
  ];
}

class _TuyaTS0505BState extends AbstractDeviceState<TuyaTS0505B> {
  /*@override
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
  };*/

  @override
  List<DeviceProperties> deviceProperties = TuyaTS0505B.tuyaTS0505BProperties;
}
