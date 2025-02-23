import 'package:flutter/material.dart';

import '../abstract_device.dart';

class Hue929001821618 extends AbstractDevice {
  const Hue929001821618(
      {super.key,
      required super.state,
      required super.friendlyName,
      required super.ieeeAddress});

  @override
  State<Hue929001821618> createState() => _Hue929001821618State();
  static final List<DeviceProperties> hue929001821618Properties = [
    DeviceProperties.brightness,
    DeviceProperties.powerOnBehaviour,
    DeviceProperties.state,
    DeviceProperties.effects
  ];
}

class _Hue929001821618State extends AbstractDeviceState<Hue929001821618> {
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
  List<DeviceProperties> deviceProperties =
      Hue929001821618.hue929001821618Properties;
}
