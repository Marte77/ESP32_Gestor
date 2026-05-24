# Zigbee MQTT Android (Kotlin)

This Android app connects directly to the `zigbee2mqtt` MQTT broker, lists available Zigbee devices from `zigbee2mqtt/bridge/devices`, and renders controls for writable exposes (binary, numeric, enum, and text).

## Requirements
- Android Studio (or Gradle) with Android SDK 34
- An MQTT broker running `zigbee2mqtt`

## Run
1. Open the `android_zigbee_kotlin` folder in Android Studio.
2. Sync Gradle and run the `app` configuration on a device/emulator.
3. Enter the broker host and port (default `192.168.3.0:1883`), then tap **Connect**.

## MQTT Topics
- Subscribes to: `zigbee2mqtt/bridge/devices`
- Publishes to: `zigbee2mqtt/bridge/request/devices`
- Sends control updates to: `zigbee2mqtt/<friendly_name>/set`
