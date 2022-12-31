abstract class MQTTSubscriberInterface {
  void subscribeToTopic();
  void publishChanges(Map<String, dynamic> map);
  void unsubscribeToTopic();
}
