const mqtt = require("mqtt");

const url = "mqtt://192.168.3.0";
const client  = mqtt.connect(url)

const mainTopic = "zigbee2mqtt/bridge/devices"

/*client.on("connect", function () {
const client = mqtt.connect(url, options);
    console.log("Connected")
});

client.on("message",function (topic, message) {
    console.log(topic)
    console.log(message)
})*/

client.on('connect', function () {
    client.subscribe(mainTopic, function (err) {
      if (!err) {
        client.publish(mainTopic, 'Hello mqtt')
      }
    })
  })
  client.on('message', function (topic, message) {
    // message is Buffer
    console.log(message.toString())
    client.end()
  })