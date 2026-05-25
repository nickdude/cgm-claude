package com.belvix.app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanResult
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import android.util.Log

import com.eaglenos.blehealth.callback.CgmAuthCallback
import com.eaglenos.blehealth.callback.CgmConnectCallback
import com.eaglenos.blehealth.callback.CgmDeviceBindingStepCallback
import com.eaglenos.blehealth.callback.CgmDeviceDataSyncProgressCallback
import com.eaglenos.blehealth.callback.CgmDeviceStateInfoCallback
import com.eaglenos.blehealth.callback.CgmLogCallback
import com.eaglenos.blehealth.callback.CgmScanCallback
import com.eaglenos.blehealth.callback.CgmSyncHistoryCallback
import com.eaglenos.blehealth.cgm.CgmDeviceManager
import com.eaglenos.blehealth.entity.CgmBloodSugar
import com.eaglenos.blehealth.entity.CgmDeviceInfo
import com.eaglenos.blehealth.entity.CgmError
import com.eaglenos.blehealth.entity.DeviceAbnormalState
import com.eaglenos.blehealth.entity.DeviceBindingStep
import com.eaglenos.blehealth.heartbeat.CgmHeartbeatCallback
import com.eaglenos.blehealth.heartbeat.CgmHeartbeatTimerUtil

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the Eaglenos CGM SDK to Flutter.
 *
 * - MethodChannel handles imperative calls from Dart (auth, scan, connect, …).
 * - EventChannel streams every SDK callback (glucose, device info, scan results,
 *   bind step, sync progress, log, errors, connection state) back to Dart.
 *
 * All sink writes go through [postEvent], which marshals onto the main thread
 * because Flutter's EventChannel sinks are not thread-safe.
 */
class CgmSdkBridge(
    private val context: Context
) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {

    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventSink: EventChannel.EventSink? = null

    /** Scan results keyed by device MAC so we can connect later. */
    private val scanResults =
        mutableMapOf<String, ScanResult>()

    private var stateCallbacksAttached = false

    private var bluetoothReceiver:
            BroadcastReceiver? = null

    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?
    ) {
        eventSink = events

        attachSdkCallbacksOnce()

        registerBluetoothReceiver()

        // Emit current state so listeners don't have to poll.
        postEvent(
            mapOf(
                "type" to "bluetoothStateChanged",
                "enabled" to isBluetoothEnabled()
            )
        )
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun isBluetoothEnabled(): Boolean {
        return try {
            val manager = context
                .getSystemService(
                    Context.BLUETOOTH_SERVICE
                ) as? BluetoothManager

            val adapter =
                manager?.adapter
                    ?: BluetoothAdapter
                        .getDefaultAdapter()

            adapter?.isEnabled == true
        } catch (_: Throwable) {
            false
        }
    }

    private fun registerBluetoothReceiver() {
        if (bluetoothReceiver != null) return

        bluetoothReceiver =
            object : BroadcastReceiver() {
                override fun onReceive(
                    ctx: Context?,
                    intent: Intent?
                ) {
                    if (intent?.action !=
                        BluetoothAdapter
                            .ACTION_STATE_CHANGED
                    ) return

                    val state = intent
                        .getIntExtra(
                            BluetoothAdapter
                                .EXTRA_STATE,
                            BluetoothAdapter
                                .ERROR
                        )

                    val enabled =
                        state ==
                            BluetoothAdapter
                                .STATE_ON

                    if (
                        state ==
                            BluetoothAdapter
                                .STATE_ON ||
                        state ==
                            BluetoothAdapter
                                .STATE_OFF
                    ) {
                        postEvent(
                            mapOf(
                                "type" to "bluetoothStateChanged",
                                "enabled" to enabled
                            )
                        )
                    }
                }
            }

        try {
            context.registerReceiver(
                bluetoothReceiver,
                IntentFilter(
                    BluetoothAdapter
                        .ACTION_STATE_CHANGED
                )
            )
        } catch (t: Throwable) {
            Log.w(
                TAG,
                "registerBluetoothReceiver failed",
                t
            )
        }
    }

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        try {
            when (call.method) {
                "init" -> {
                    // SDK init happens in BelvixApplication.onCreate(); this is a noop
                    // but we still wire callbacks here in case Dart calls init after
                    // listening to the event channel.
                    attachSdkCallbacksOnce()
                    result.success(true)
                }

                "auth" -> {
                    val appId = call.argument<String>("appId")
                    val appSecret = call.argument<String>("appSecret")

                    if (appId.isNullOrBlank() ||
                        appSecret.isNullOrBlank()) {
                        result.error(
                            "ARG",
                            "appId and appSecret are required",
                            null
                        )
                        return
                    }

                    CgmDeviceManager.getInstance().authCert(
                        appId,
                        appSecret,
                        object : CgmAuthCallback {
                            override fun onSuccess() {
                                postEvent(
                                    mapOf(
                                        "type" to "authResult",
                                        "success" to true
                                    )
                                )
                                result.success(true)
                            }

                            override fun onError(error: CgmError) {
                                postEvent(
                                    mapOf(
                                        "type" to "authResult",
                                        "success" to false,
                                        "error" to errorToMap(error)
                                    )
                                )
                                postEvent(errorEvent("auth", error))
                                result.success(false)
                            }
                        }
                    )
                }

                "checkAuthorized" -> {
                    result.success(
                        CgmDeviceManager.getInstance().checkAuthorized()
                    )
                }

                "startScan" -> {
                    scanResults.clear()
                    postEvent(mapOf("type" to "scanStarted"))

                    CgmDeviceManager.getInstance().startScanBluetooth(
                        object : CgmScanCallback {
                            override fun onScanResult(
                                callbackType: Int,
                                scanResult: ScanResult
                            ) {
                                val device = scanResult.device

                                if (device != null) {
                                    scanResults[device.address] = scanResult
                                }

                                postEvent(scanResultEvent(scanResult))
                            }

                            override fun onScanFailed(
                                errorCode: Int,
                                message: String?
                            ) {
                                postEvent(
                                    mapOf(
                                        "type" to "error",
                                        "source" to "scan",
                                        "errorCode" to errorCode,
                                        "error" to (message ?: "scan failed")
                                    )
                                )
                            }
                        }
                    )
                    result.success(true)
                }

                "stopScan" -> {
                    CgmDeviceManager.getInstance().stopScanBluetooth()
                    postEvent(mapOf("type" to "scanStopped"))
                    result.success(true)
                }

                "connect" -> {
                    val sn = call.argument<String>("sn")

                    if (sn.isNullOrBlank()) {
                        result.error(
                            "ARG",
                            "sn is required",
                            null
                        )
                        return
                    }

                    val autoConnect =
                        call.argument<Boolean>("autoConnect") ?: false

                    CgmDeviceManager.getInstance().connectTargetAndStartScan(
                        sn,
                        autoConnect,
                        object : CgmConnectCallback {
                            override fun onDeviceDisconnected() {
                                postEvent(
                                    mapOf(
                                        "type" to "disconnected",
                                        "sn" to sn
                                    )
                                )
                            }

                            override fun onSuccess() {
                                postEvent(
                                    mapOf(
                                        "type" to "connected",
                                        "sn" to sn
                                    )
                                )
                            }

                            override fun onFailure(error: CgmError) {
                                postEvent(
                                    errorEvent("connect", error).plus(
                                        "sn" to sn
                                    )
                                )
                            }
                        }
                    )
                    // Async — bind step events drive UI; we return immediately.
                    result.success(true)
                }

                "disconnect" -> {
                    CgmDeviceManager.getInstance().disconnectDevice()
                    result.success(true)
                }

                "isConnected" -> {
                    // The SDK exposes connection state via callbacks; we return
                    // a best-effort by checking if a sensor SN is currently set.
                    result.success(
                        !CgmDeviceManager.getInstance().sn.isNullOrEmpty()
                    )
                }

                "getHistory" -> {
                    val sn = call.argument<String>("sn")
                    val indexStart =
                        call.argument<Int>("indexStart") ?: 1

                    if (sn.isNullOrBlank()) {
                        result.error(
                            "ARG",
                            "sn is required",
                            null
                        )
                        return
                    }

                    CgmDeviceManager.getInstance().getHistoryFromIndexStart(
                        sn,
                        indexStart,
                        object : CgmSyncHistoryCallback {
                            override fun onSyncHistorySuccess(
                                bloodSugarData: MutableList<CgmBloodSugar>
                            ) {
                                result.success(
                                    bloodSugarData.map(::bloodSugarToMap)
                                )
                            }

                            override fun onSyncHistoryFailed(error: CgmError) {
                                result.error(
                                    error.code.toString(),
                                    error.message,
                                    null
                                )
                            }
                        }
                    )
                }

                "startHeartbeat" -> {
                    CgmHeartbeatTimerUtil.INSTANCE.startHeartbeat(
                        context,
                        object : CgmHeartbeatCallback {
                            override fun onHeartbeatStart() {
                                postEvent(
                                    mapOf(
                                        "type" to "heartbeat",
                                        "state" to "start"
                                    )
                                )
                            }

                            override fun onHeartbeatStop() {
                                postEvent(
                                    mapOf(
                                        "type" to "heartbeat",
                                        "state" to "stop"
                                    )
                                )
                            }
                        }
                    )
                    result.success(true)
                }

                "stopHeartbeat" -> {
                    CgmHeartbeatTimerUtil.INSTANCE.stopHeartbeat()
                    result.success(true)
                }

                "isBluetoothEnabled" -> {
                    result.success(
                        isBluetoothEnabled()
                    )
                }

                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            Log.e(TAG, "Method ${call.method} crashed", t)
            result.error(
                "NATIVE",
                t.message ?: t.javaClass.simpleName,
                null
            )
        }
    }

    private fun attachSdkCallbacksOnce() {
        if (stateCallbacksAttached) return

        stateCallbacksAttached = true

        val manager = CgmDeviceManager.getInstance()

        manager.setCgmDeviceStateInfoCallback(
            object : CgmDeviceStateInfoCallback {
                override fun onFailed(error: CgmError) {
                    postEvent(errorEvent("state", error))
                }

                override fun onGlucoseDataWithErrorReceived(
                    isAbandoned: Boolean,
                    isErrorShow: Boolean,
                    abnormalStates: MutableList<DeviceAbnormalState>,
                    bloodSugars: MutableList<CgmBloodSugar>
                ) {
                    postEvent(
                        mapOf(
                            "type" to "glucoseData",
                            "isAbandoned" to isAbandoned,
                            "isErrorShow" to isErrorShow,
                            "abnormalStates" to
                                abnormalStates.map { it.name },
                            "bloodSugars" to
                                bloodSugars.map(::bloodSugarToMap)
                        )
                    )
                }

                override fun onDeviceInfoReceived(info: CgmDeviceInfo?) {
                    if (info == null) return

                    postEvent(deviceInfoEvent(info))
                }
            }
        )

        manager.setCgmDeviceDataSyncProgressCallback(
            CgmDeviceDataSyncProgressCallback { progress ->
                postEvent(
                    mapOf(
                        "type" to "syncProgress",
                        "progress" to progress
                    )
                )
            }
        )

        manager.setCgmBindStepCallback(
            CgmDeviceBindingStepCallback { step ->
                postEvent(
                    mapOf(
                        "type" to "bindStep",
                        "step" to step.name
                    )
                )
            }
        )

        manager.setCgmLogCallback(
            CgmLogCallback { message ->
                postEvent(
                    mapOf(
                        "type" to "log",
                        "message" to (message ?: "")
                    )
                )
            }
        )
    }

    private fun postEvent(event: Map<String, Any?>) {
        // Sink writes must happen on the main thread.
        mainHandler.post {
            try {
                eventSink?.success(event)
            } catch (t: Throwable) {
                Log.w(TAG, "postEvent failed", t)
            }
        }
    }

    private fun scanResultEvent(scan: ScanResult): Map<String, Any?> {
        val device = scan.device

        return mapOf(
            "type" to "scanResult",
            "deviceName" to (device?.name ?: ""),
            "deviceAddress" to (device?.address ?: ""),
            "rssi" to scan.rssi
        )
    }

    private fun deviceInfoEvent(
        info: CgmDeviceInfo
    ): Map<String, Any?> {
        return mapOf(
            "type" to "deviceInfo",
            "sn" to CgmDeviceManager.getInstance().sn,
            "firmwareVersion" to (info.firmwareVersion ?: ""),
            "measurementInterval" to info.measurementInterval,
            "deviceActivateTimestamp" to info.deviceActivateTimestamp,
            "timeOffset" to info.timeOffset,
            "isPreheating" to info.isPreheating,
            "isInUse" to info.isInUse,
            "isExpired" to info.isExpired,
            "isDeviceReset" to info.isDeviceReset,
            "abnormalStates" to
                (info.abnormalStates?.map { it.name } ?: emptyList<String>())
        )
    }

    private fun bloodSugarToMap(
        bs: CgmBloodSugar
    ): Map<String, Any?> {
        return mapOf(
            "originalBloodSugar" to bs.originalBloodSugar,
            "processedBloodSugar" to bs.processedBloodSugar,
            "connectCode" to (bs.connectCode ?: ""),
            "createTime" to bs.createTime,
            "timeOffset" to bs.timeOffset,
            "measurementStatus" to bs.measurementStatus,
            "current" to bs.current,
            "temperature" to bs.temperature,
            "batteryVoltage" to bs.batteryVoltage,
            "trend" to bs.trend
        )
    }

    private fun errorToMap(error: CgmError): Map<String, Any?> {
        return mapOf(
            "name" to error.name,
            "code" to error.code,
            "message" to (error.message ?: "")
        )
    }

    private fun errorEvent(
        source: String,
        error: CgmError
    ): Map<String, Any?> {
        return mapOf(
            "type" to "error",
            "source" to source,
            "errorCode" to error.code,
            "errorName" to error.name,
            "error" to (error.message ?: "")
        )
    }

    companion object {
        private const val TAG = "CgmSdkBridge"
    }
}
