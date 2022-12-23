import 'package:esp32_frontend/util/support_web_mobile/impl/base_finder.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttFinderImpl extends MqttFinderBase {
  static final MqttFinderImpl _impl = MqttFinderImpl._internal();
  final MqttServerClient _mqttClient = MqttServerClient.withPort(
      MqttFinderBase.ip, MqttFinderBase.clientId, MqttFinderBase.port);
  factory MqttFinderImpl() {
    return _impl;
  }
  MqttFinderImpl._internal();
  @override
  MqttClient getClient() {
    return _mqttClient;
  }
}
