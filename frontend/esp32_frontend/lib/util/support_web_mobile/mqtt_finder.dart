// ignore: unused_import
import 'package:esp32_frontend/util/support_web_mobile/impl/stub_finder.dart'
    if (dart.library.io) 'package:esp32_frontend/util/support_web_mobile/impl/mobile_finder.dart' //mobile
    if (dart.library.html) 'package:esp32_frontend/util/support_web_mobile/impl/web_finder.dart'; //web
import 'package:mqtt_client/mqtt_client.dart';

class MqttFinder {
  final MqttFinderImpl _finder;
  MqttFinder() : _finder = MqttFinderImpl();
  MqttClient getClient() {
    return _finder.getClient();
  }
}
