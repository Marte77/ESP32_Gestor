import 'package:esp32_frontend/util/mqtt_subscriber_interface.dart';
import 'package:esp32_frontend/widgets/devices/devices/abstract_device_main_card.dart';
import 'package:esp32_frontend/widgets/devices/devices/abstract_device.dart';
import 'package:esp32_frontend/widgets/devices/devices/hue_929001821618/hue_929001821618.dart';
import 'package:flutter/material.dart';

class Hue929001821618MainCard extends AbstractDeviceMainCard {
  const Hue929001821618MainCard(
      {super.key,
      required super.friendlyName,
      required super.state,
      required super.ieeeAddress});

  @override
  State<Hue929001821618MainCard> createState() =>
      _Hue929001821618MainCardState();
}

class _Hue929001821618MainCardState
    extends AbstractDeviceMainCardState<Hue929001821618MainCard>
    implements MQTTSubscriberInterface {
  @override
  List<DeviceProperties> deviceProperties =
      Hue929001821618.hue929001821618Properties;
}
