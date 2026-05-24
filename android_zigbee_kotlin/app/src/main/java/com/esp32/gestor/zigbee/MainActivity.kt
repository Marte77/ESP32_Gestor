package com.esp32.gestor.zigbee

import android.os.Bundle
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.SeekBar
import android.widget.Spinner
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.widget.SwitchCompat
import org.eclipse.paho.android.service.MqttAndroidClient
import org.eclipse.paho.client.mqttv3.IMqttActionListener
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken
import org.eclipse.paho.client.mqttv3.IMqttToken
import org.eclipse.paho.client.mqttv3.MqttCallbackExtended
import org.eclipse.paho.client.mqttv3.MqttClient
import org.eclipse.paho.client.mqttv3.MqttConnectOptions
import org.eclipse.paho.client.mqttv3.MqttMessage
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : AppCompatActivity() {
    private lateinit var brokerHostInput: EditText
    private lateinit var brokerPortInput: EditText
    private lateinit var connectButton: Button
    private lateinit var statusText: TextView
    private lateinit var deviceContainer: LinearLayout

    private var mqttClient: MqttAndroidClient? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        brokerHostInput = findViewById(R.id.brokerHost)
        brokerPortInput = findViewById(R.id.brokerPort)
        connectButton = findViewById(R.id.connectButton)
        statusText = findViewById(R.id.statusText)
        deviceContainer = findViewById(R.id.deviceContainer)

        connectButton.setOnClickListener {
            connectToBroker()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        mqttClient?.unregisterResources()
        mqttClient?.close()
    }

    private fun connectToBroker() {
        val host = brokerHostInput.text.toString().trim()
        val port = brokerPortInput.text.toString().trim()
        if (host.isEmpty() || port.isEmpty()) {
            showToast("Define broker host and port")
            return
        }
        val serverUri = "tcp://$host:$port"
        mqttClient?.unregisterResources()
        mqttClient?.close()
        mqttClient = MqttAndroidClient(applicationContext, serverUri, MqttClient.generateClientId()).apply {
            setCallback(object : MqttCallbackExtended {
                override fun connectComplete(reconnect: Boolean, serverURI: String?) {
                    updateStatus("Connected to $serverUri")
                    subscribeToDevices()
                    requestDeviceList()
                }

                override fun connectionLost(cause: Throwable?) {
                    updateStatus("Connection lost: ${cause?.message ?: "unknown"}")
                }

                override fun messageArrived(topic: String?, message: MqttMessage?) {
                    if (topic == null || message == null) return
                    if (topic == DEVICES_TOPIC) {
                        val payload = message.payload?.decodeToString() ?: return
                        val devices = parseDevices(payload)
                        renderDevices(devices)
                    }
                }

                override fun deliveryComplete(token: IMqttDeliveryToken?) = Unit
            })
        }

        val options = MqttConnectOptions().apply {
            isAutomaticReconnect = true
            isCleanSession = true
            connectionTimeout = 10
        }

        updateStatus("Connecting to $serverUri...")
        mqttClient?.connect(options, null, object : IMqttActionListener {
            override fun onSuccess(asyncActionToken: IMqttToken?) {
                updateStatus("Connected to $serverUri")
                subscribeToDevices()
                requestDeviceList()
            }

            override fun onFailure(asyncActionToken: IMqttToken?, exception: Throwable?) {
                updateStatus("Connection failed: ${exception?.message ?: "unknown"}")
            }
        })
    }

    private fun subscribeToDevices() {
        mqttClient?.subscribe(DEVICES_TOPIC, 1, null, object : IMqttActionListener {
            override fun onSuccess(asyncActionToken: IMqttToken?) {
                updateStatus("Subscribed to $DEVICES_TOPIC")
            }

            override fun onFailure(asyncActionToken: IMqttToken?, exception: Throwable?) {
                updateStatus("Failed to subscribe: ${exception?.message ?: "unknown"}")
            }
        })
    }

    private fun requestDeviceList() {
        val payload = JSONObject().toString().toByteArray()
        val message = MqttMessage(payload).apply { qos = 1 }
        mqttClient?.publish(DEVICE_REQUEST_TOPIC, message)
    }

    private fun renderDevices(devices: List<Device>) {
        runOnUiThread {
            deviceContainer.removeAllViews()
            if (devices.isEmpty()) {
                deviceContainer.addView(textView("No Zigbee devices found."))
                return@runOnUiThread
            }
            devices.forEachIndexed { index, device ->
                deviceContainer.addView(buildDeviceView(device))
                if (index != devices.lastIndex) {
                    deviceContainer.addView(divider())
                }
            }
        }
    }

    private fun buildDeviceView(device: Device): View {
        val wrapper = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(24, 24, 24, 24)
        }
        wrapper.addView(textView(device.friendlyName, true))
        device.description?.let { wrapper.addView(textView(it)) }
        device.model?.let { wrapper.addView(textView("Model: $it")) }
        device.vendor?.let { wrapper.addView(textView("Vendor: $it")) }

        val writableExposes = device.exposes.filter { it.isWritable() }
        if (writableExposes.isEmpty()) {
            wrapper.addView(textView("No writable exposes found for this device."))
            return wrapper
        }

        writableExposes.forEach { expose ->
            wrapper.addView(exposeLabel(expose))
            val control = when (expose.type) {
                "binary" -> buildBinaryControl(device, expose)
                "numeric" -> buildNumericControl(device, expose)
                "enum" -> buildEnumControl(device, expose)
                "text" -> buildTextControl(device, expose)
                else -> textView("Unsupported expose type: ${expose.type}")
            }
            wrapper.addView(control)
        }
        return wrapper
    }

    private fun exposeLabel(expose: Expose): TextView {
        val labelText = buildString {
            append(expose.label)
            if (!expose.unit.isNullOrBlank()) {
                append(" (${expose.unit})")
            }
        }
        return textView(labelText, false, 16f).apply {
            setPadding(0, 16, 0, 8)
        }
    }

    private fun buildBinaryControl(device: Device, expose: Expose): View {
        val switch = SwitchCompat(this)
        switch.text = expose.property ?: "toggle"
        switch.setOnCheckedChangeListener { _, isChecked ->
            val value = if (isChecked) expose.valueOn ?: "ON" else expose.valueOff ?: "OFF"
            publishProperty(device.friendlyName, expose.property, value)
        }
        return switch
    }

    private fun buildNumericControl(device: Device, expose: Expose): View {
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }
        val valueText = textView("Value: ${expose.valueMin ?: 0}")
        val min = expose.valueMin ?: 0
        val max = expose.valueMax ?: 100
        val range = (max - min).coerceAtLeast(1)
        val seekBar = SeekBar(this).apply {
            this.max = range
            progress = 0
        }
        seekBar.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                val current = min + progress
                valueText.text = "Value: $current"
            }

            override fun onStartTrackingTouch(seekBar: SeekBar?) = Unit

            override fun onStopTrackingTouch(seekBar: SeekBar?) {
                val current = min + (seekBar?.progress ?: 0)
                publishProperty(device.friendlyName, expose.property, current)
            }
        })
        container.addView(valueText)
        container.addView(seekBar)
        return container
    }

    private fun buildEnumControl(device: Device, expose: Expose): View {
        val spinner = Spinner(this)
        val values = expose.values ?: emptyList()
        if (values.isEmpty()) {
            return textView("Enum has no values.")
        }
        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, values).apply {
            setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        }
        spinner.adapter = adapter
        var initial = true
        spinner.onItemSelectedListener = object : android.widget.AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: android.widget.AdapterView<*>?, view: View?, position: Int, id: Long) {
                if (initial) {
                    initial = false
                    return
                }
                publishProperty(device.friendlyName, expose.property, values[position])
            }

            override fun onNothingSelected(parent: android.widget.AdapterView<*>?) = Unit
        }
        return spinner
    }

    private fun buildTextControl(device: Device, expose: Expose): View {
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        val input = EditText(this).apply {
            hint = "Enter value"
            inputType = InputType.TYPE_CLASS_TEXT
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        val button = Button(this).apply {
            text = "Send"
            setOnClickListener {
                val value = input.text.toString()
                if (value.isBlank()) {
                    showToast("Enter a value to send")
                } else {
                    publishProperty(device.friendlyName, expose.property, value)
                }
            }
        }
        container.addView(input)
        container.addView(button)
        return container
    }

    private fun publishProperty(friendlyName: String, property: String?, value: Any) {
        if (property.isNullOrBlank()) {
            showToast("Expose property is missing.")
            return
        }
        val payload = JSONObject().apply {
            put(property, value)
        }.toString()
        val message = MqttMessage(payload.toByteArray()).apply { qos = 1 }
        val topic = "zigbee2mqtt/$friendlyName/set"
        try {
            mqttClient?.publish(topic, message)
        } catch (ex: Exception) {
            showToast("Publish failed: ${ex.message ?: "unknown"}")
        }
    }

    private fun parseDevices(payload: String): List<Device> {
        val json = JSONArray(payload)
        val devices = mutableListOf<Device>()
        for (i in 0 until json.length()) {
            val device = json.optJSONObject(i) ?: continue
            if (device.optString("type") == "Coordinator") continue
            val friendlyName = device.optString("friendly_name")
            val definition = device.optJSONObject("definition")
            val exposes = definition?.optJSONArray("exposes") ?: device.optJSONArray("exposes")
            val exposeList = flattenExposes(exposes)
            devices.add(
                Device(
                    friendlyName = friendlyName.ifBlank { "Unknown device" },
                    description = definition?.optString("description"),
                    model = definition?.optString("model"),
                    vendor = definition?.optString("vendor"),
                    exposes = exposeList
                )
            )
        }
        return devices
    }

    private fun flattenExposes(exposes: JSONArray?): List<Expose> {
        val list = mutableListOf<Expose>()
        if (exposes == null) return list
        for (i in 0 until exposes.length()) {
            val exposeObj = exposes.optJSONObject(i) ?: continue
            val features = exposeObj.optJSONArray("features")
            if (features != null) {
                list.addAll(flattenExposes(features))
                continue
            }
            val property = exposeObj.optString("property").ifBlank {
                exposeObj.optString("name")
            }
            val label = exposeObj.optString("label").ifBlank {
                property.ifBlank { "Expose" }
            }
            val values = exposeObj.optJSONArray("values")?.let { valuesArray ->
                List(valuesArray.length()) { index -> valuesArray.optString(index) }
            }
            list.add(
                Expose(
                    label = label,
                    property = property.ifBlank { null },
                    type = exposeObj.optString("type"),
                    access = exposeObj.optInt("access", 0),
                    valueMin = exposeObj.optInt("value_min", 0).takeIf { exposeObj.has("value_min") },
                    valueMax = exposeObj.optInt("value_max", 0).takeIf { exposeObj.has("value_max") },
                    values = values,
                    valueOn = exposeObj.opt("value_on")?.toString(),
                    valueOff = exposeObj.opt("value_off")?.toString(),
                    unit = exposeObj.optString("unit")
                )
            )
        }
        return list
    }

    private fun textView(text: String, bold: Boolean = false, size: Float = 14f): TextView {
        return TextView(this).apply {
            this.text = text
            textSize = size
            if (bold) {
                setTypeface(typeface, android.graphics.Typeface.BOLD)
            }
        }
    }

    private fun divider(): View {
        return View(this).apply {
            setBackgroundColor(0xFFE0E0E0.toInt())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                2
            ).apply {
                setMargins(0, 12, 0, 12)
            }
        }
    }

    private fun updateStatus(message: String) {
        runOnUiThread {
            statusText.text = message
        }
    }

    private fun showToast(message: String) {
        runOnUiThread {
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
        }
    }

    data class Device(
        val friendlyName: String,
        val description: String?,
        val model: String?,
        val vendor: String?,
        val exposes: List<Expose>
    )

    data class Expose(
        val label: String,
        val property: String?,
        val type: String,
        val access: Int,
        val valueMin: Int?,
        val valueMax: Int?,
        val values: List<String>?,
        val valueOn: String?,
        val valueOff: String?,
        val unit: String?
    ) {
        fun isWritable(): Boolean = access and 2 == 2
    }

    companion object {
        private const val DEVICES_TOPIC = "zigbee2mqtt/bridge/devices"
        private const val DEVICE_REQUEST_TOPIC = "zigbee2mqtt/bridge/request/devices"
    }
}
