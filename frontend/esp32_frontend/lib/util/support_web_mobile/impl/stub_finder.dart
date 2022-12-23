import 'package:esp32_frontend/util/support_web_mobile/impl/base_finder.dart';
import 'package:mqtt_client/mqtt_client.dart';

class MqttFinderImpl extends MqttFinderBase {
  @override
  MqttClient getClient() {
    throw UnsupportedError("Accessing Stub");
  }
}
