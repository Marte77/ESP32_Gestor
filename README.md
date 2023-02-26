# ESP32_Gestor - ESP32 with LED Strip light

# arduino folder
- contains the code of the ESP32. This code uses the 2 cores in the ESP32, where the main process takes care of the wifi communication, sending, every X seconds, the status of the device to the backend, and whenever it receives a request to change the mode, it kills the second process and restarts it. It's kinda buggy but I haven't felt like debugging it (it seems to not respond after multiple requests that were sent within a small interval of time, idk for sure)
- it only depends on the backend folder and an HTTP client in order to run normally
# backend folder
- contains an express.js project that stores the status of all the ESP32 that are connected to them, in order to show in the frontend page
- uses node.js, express.js and a sqlite database

# frontend folder
- shows the state of the current ESP32 devices (haven't tested more than one, since I only have one, so I don't know if it works)
- also has integration with Zigbee2Mqtt, showing the devices that the zigbee2mqtt has stored, currently only supports 2 tuya lightbulbs (they're similar models, so it's more like 1 lightbulb) and nothing else since I don't have any other ZigBee devices
- depends on the backend folder program running and also an MQTT broker (Zigbee2mqtt to establish a connection with ZigBee devices). 
