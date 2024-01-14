import 'package:esp32_frontend/util/mqtt_subscriber_interface.dart';
import 'package:esp32_frontend/widgets/devices/devices/abstract_device_main_card.dart';
import 'package:esp32_frontend/widgets/devices/devices/abstract_device.dart';
import 'package:esp32_frontend/widgets/devices/devices/tuya_ts0505b/tuya_ts0505b.dart';
import 'package:flutter/material.dart';

class TuyaTS0505bMainCard extends AbstractDeviceMainCard {
  const TuyaTS0505bMainCard(
      {super.key,
      required super.mqttClient,
      required super.friendlyName,
      required super.state,
      required super.ieeeAddress});

  @override
  State<TuyaTS0505bMainCard> createState() => _TuyaTS0505bMainCardState();
}

class _TuyaTS0505bMainCardState
    extends AbstractDeviceMainCardState<TuyaTS0505bMainCard>
    implements MQTTSubscriberInterface {
  @override
  List<DeviceProperties> deviceProperties = TuyaTS0505B.tuyaTS0505BProperties;
}
