import 'package:mqtt_client/mqtt_client.dart';

abstract class MqttFinderBase {
  static String ip = "192.168.3.0";
  static String ipWeb = "ws://$ip";
  static String clientId = 'boas';
  static int port = 1883, portWeb = 8079;
  MqttClient getClient();
}
