import 'package:esp32_frontend/util/support_web_mobile/impl/base_finder.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MqttFinderImpl extends MqttFinderBase {
  static final MqttFinderImpl _impl = MqttFinderImpl._internal();
  final MqttBrowserClient _mqttClient = MqttBrowserClient.withPort(
      MqttFinderBase.ipWeb, MqttFinderBase.clientId, MqttFinderBase.portWeb);
  factory MqttFinderImpl() {
    return _impl;
  }
  MqttFinderImpl._internal();
  @override
  MqttClient getClient() {
    return _mqttClient;
  }
}
