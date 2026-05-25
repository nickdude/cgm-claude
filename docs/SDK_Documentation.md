# eagleSDKDemo

## 1. Introduction

This SDK is only available to authorized apps. Unauthorized apps cannot use its features. **Authentication** must be completed before using the SDK; otherwise, full functionality will not be available.

This SDK supports receiving glucose data from the Jingjie continuous glucose monitoring (CGM) system. Simply call the method and pass the sensor SN to enable Bluetooth connection and data reception.

**All public methods are accessed via the singleton `CgmDeviceManager.getInstance()`.**

## 2. Permissions Declaration

The SDK declares the following permissions in its manifest file:

```xml
<!-- ************************ Declares Bluetooth hardware – devices without Bluetooth cannot install or use ******************** -->
<uses-feature
    android:name="android.hardware.bluetooth" /><!-- ************************ Bluetooth permissions, Android 11 and below ******************** -->
<uses-permission android:name="android.permission.BLUETOOTH"
android:maxSdkVersion="30" /><uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
android:maxSdkVersion="30" /><!-- ************************ Location permissions required for Bluetooth scanning, Android 11 and below ******************** -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
android:maxSdkVersion="30" /><uses-permission
android:name="android.permission.ACCESS_COARSE_LOCATION"
android:maxSdkVersion="30" /><uses-permission
android:name="android.permission.ACCESS_BACKGROUND_LOCATION"
android:maxSdkVersion="30" /><!-- ************************ Bluetooth permissions, Android 12 and above ******************** -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
android:usesPermissionFlags="neverForLocation" /><uses-permission
android:name="android.permission.BLUETOOTH_CONNECT" /><uses-permission
android:name="android.permission.ACCESS_NETWORK_STATE" /><uses-permission
android:name="android.permission.SCHEDULE_EXACT_ALARM" /><uses-permission
android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```

**Core permission notes**:

- Bluetooth scanning and connection require `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` (Android 12+) or `BLUETOOTH` / `BLUETOOTH_ADMIN` (Android 11-).
- Bluetooth scanning requires location permissions. On Android 11-, `ACCESS_FINE_LOCATION` or `ACCESS_COARSE_LOCATION` must be requested.
- Background scanning (Android 10-11) requires `ACCESS_BACKGROUND_LOCATION`.
- If your app does not want to declare certain non‑essential permissions (e.g., alarm, ignore battery optimization), you can remove them as follows:
  ```xml
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" tools:node="remove" />
  ```

## 3. Installation Guide

1. Copy the `bleHealth-release.aar` file to the `libs` directory of your app module (create the `libs` directory if it does not exist).
2. Add the dependency in your app module's `build.gradle.kts` file:
   ```kotlin
   implementation(files("libs/bleHealth-release.aar"))
   ```

## 4. Initialization

Call the initialization method in your custom `Application` class to initialize the SDK globally (only once):

```java
/**
 * Initialize the SDK
 * It is recommended to call this in Application.onCreate()
 * @param context application
 */
void init(Application context);
```

Example:

```java
public class MyApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        CgmDeviceManager.getInstance().init(this);
    }
}
```

## 5. SDK Authentication

**Core requirement**: The SDK must be authenticated before all features can be used normally. The `appId` and `appSecret` must be obtained from the SDK provider.

```java
/**
 * Authentication
 * @param appId     Parameter 1 obtained from the SDK provider
 * @param appSecret Parameter 2 obtained from the SDK provider
 * @param callback  Authentication callback
 */
void authCert(String appId, String appSecret, CgmAuthCallback callback);

/**
 * Authentication callback
 */
public interface CgmAuthCallback {
    void onSuccess();

    void onError(CgmError error);
}

/**
 * Check whether the SDK is authenticated
 */
boolean checkAuthorized();
```

## 6. Usage Guide

### Important Notes

Sensitive Bluetooth permissions (e.g., Bluetooth scan, connect, location) must be requested **by the app itself**. The SDK does not handle permission requests.

### Permission Handling

The SDK provides a permission helper class `CgmPermissionHelper`, which requires a `ComponentActivity` instance.

```java
CgmPermissionHelper cgmPermissionHelper = new CgmPermissionHelper(this);  // this is a ComponentActivity instance

/**
 * Get all essential Bluetooth permissions (compatible with all Android versions)
 */
String[] getBluetoothPermissions();

/**
 * Get basic location permissions
 */
String[] getLocationPermissions();

/**
 * Get background location permission (required only for Android 10-11)
 */
String[] getBackgroundLocationPermissions();

/**
 * Check if all permissions in the array are granted
 */
boolean hasPermissions(String[] permissions);

/**
 * Check if any permission in the array is permanently denied
 */
boolean hasPermanentlyDenied(String[] permissions);

/**
 * Request Bluetooth permissions (automatically includes legacy location permissions)
 */
void requestBluetoothPermission(CgmPermissionCallback callback);

/**
 * Request background location permission (optimized logic)
 * If basic location permission is not granted, it will request location first, then background location
 */
void requestBackgroundLocationPermission(CgmPermissionCallback callback);

/**
 * Combined request: Bluetooth + background location (recommended, one‑stop solution)
 */
void requestBleAndBackgroundPermission(CgmPermissionCallback callback);

/**
 * Request to ignore battery optimization (navigate user to system settings)
 * Note: Apps are strongly advised to request this permission to prevent being restricted from running in the background
 */
void requestIgnoreBatteryOptimization(CgmPermissionCallback callback);
```

**Permission callback interface definition**:

```java
public interface CgmPermissionCallback {
    // All permissions granted
    void onAllGranted();

    // Permission denied
    void onDenied();

    // Permission permanently denied
    void onPermanentlyDenied();
}
```

### Bluetooth Scanning

- Scan service UUID: `0000000a-0000-1000-8000-00805f9b34fb` (the app can implement custom scanning logic)

```java
/**
 * Start Bluetooth scanning
 */
void startScanBluetooth(CgmScanCallback callBack);

/**
 * Bluetooth scan callback
 */
public interface CgmScanCallback {
    void onScanResult(int callbackType, ScanResult result);

    void onScanFailed(int errorCode, String message);
}

/**
 * Stop Bluetooth scanning
 */
void stopScanBluetooth();
```

### Connecting to Bluetooth Device

- Automatic Bluetooth reconnection is not effective on higher Android versions. It is recommended that the app handles disconnection and reconnection logic itself.

```java
/**
 * Scan and connect to device. Scanning lasts up to 30 seconds, after which it automatically stops.
 * @param sn            Sensor SN
 * @param isAutoConnect Whether to auto‑connect (mostly ineffective on high versions, recommend false)
 * @param callback      Connection callback
 */
void connectTargetAndStartScan(String sn, boolean isAutoConnect, CgmConnectCallback callback);

/**
 * Connect to device
 * @param scanResult    Bluetooth scan result
 * @param sn            Sensor SN
 * @param isAutoConnect Whether to auto‑connect (recommend false)
 * @param callback      Connection callback
 */
void connectTargetDevice(ScanResult scanResult, String sn, boolean isAutoConnect, CgmConnectCallback callback);

/**
 * Disconnect the device
 */
void disconnectDevice();

/**
 * Device connection status
 */
boolean isConnected();

/**
 * CGM device connection callback interface
 */
public interface CgmConnectCallback {
    void onDeviceDisconnected();

    void onSuccess();

    void onFailure(CgmError error);
}
```

### Bluetooth Device Reconnection

Although the SDK provides an auto‑reconnect parameter, it is largely ineffective on higher Android versions. It is recommended that the app periodically checks or performs scanning and passes the scan result to the SDK. The SDK provides a heartbeat utility class `CgmHeartbeatTimerUtil` (singleton).

**Manifest registration (required)**:

```xml
<receiver android:enabled="true" android:exported="true"
    android:name="com.eaglenos.blehealth.heartbeat.CgmHeartbeatStopReceiver"
    android:permission="android.permission.WAKE_LOCK" />
<receiver android:enabled="true" android:exported="true"
    android:name="com.eaglenos.blehealth.heartbeat.CgmHeartbeatStartReceiver"
    android:permission="android.permission.WAKE_LOCK" />
```

```java
/**
 * Start heartbeat task, runs periodically every 5 minutes, each run lasts 30 seconds
 * Before calling this method, the above two receivers must be registered in the manifest
 * Get instance: CgmHeartbeatTimerUtil.INSTANCE
 */
void startHeartbeat(Context context, CgmHeartbeatCallback cgmHeartbeatCallback);

/**
 * Stop heartbeat task
 */
void stopHeartbeat();

/**
 * Heartbeat callback
 */
public interface CgmHeartbeatCallback {
    /**
     * Heartbeat task starts, executes every 5 minutes. Perform Bluetooth scan and reconnection here.
     */
    void onHeartbeatStart();

    /**
     * Called 30 seconds after heartbeat start. Stop Bluetooth scanning here to avoid long scanning.
     */
    void onHeartbeatStop();
}
```

Example (Kotlin):

```kotlin
CgmHeartbeatTimerUtil.getInstance().startHeartbeat(mContext, object : CgmHeartbeatCallback {
    override fun onHeartbeatStart() {
        // Start scanning
        CgmDeviceManager.getInstance().startScanBluetooth(object : DeviceScanCallback {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                // Connect to target device when found
                CgmDeviceManager.getInstance()
                    .connectTargetDevice(result, sn, false, cgmConnectCallback)
            }
            override fun onScanFailed(errorCode: Int, msg: String) {}
        })
    }
    override fun onHeartbeatStop() {
        CgmDeviceManager.getInstance().stopScanBluetooth()
    }
})
```

### Device Information and Glucose Data Callbacks

```java
/**
 * Set listeners for device status, errors, and glucose data
 */
void setCgmDeviceStateInfoCallback(CgmDeviceStateInfoCallback callback);

/**
 * CGM device status and information callback interface
 */
public interface CgmDeviceStateInfoCallback {
    void onFailed(CgmError error);

    /**
     * @param isAbandoned    Device is broken and cannot be used
     * @param isErrorShow    Device has an error but can still be used, user should be notified
     * @param abnormalStates List of device abnormal state enums
     * @param bloodSugars    Real‑time glucose data (including real‑time data and historical data being synced)
     *                       Fully synced historical data can be retrieved via getHistoryFromIndexStart
     */
    void onGlucoseDataWithErrorReceived(boolean isAbandoned, boolean isErrorShow,
                                        List<DeviceAbnormalState> abnormalStates,
                                        List<CgmBloodSugar> bloodSugars);

    /**
     * Device information callback (returns activation time, serial number, firmware version, measurement interval, device status, etc. after successful connection)
     */
    void onDeviceInfoReceived(CgmDeviceInfo cgmDeviceInfo);
}

/**
 * Device abnormal state enum
 */
public enum DeviceAbnormalState {
    LowBattery(0),            // Low battery
    TemperatureTooHigh(1),    // Device temperature too high
    TemperatureTooLow(2),     // Device temperature too low
    AfeAbnormal(3),           // AFE abnormal
    CurrentInvalid(4),        // Current too high or too low, device invalid
    GlucoseChangeTooFast(5),  // Glucose change too fast, device invalid
    StateReserve1(6), StateReserve2(7),
    BatteryReset(99);         // Device battery reset (device powered off/restarted, must be discarded afterwards)
}

/**
 * Glucose data model
 */
public class CgmBloodSugar {
    public float originalBloodSugar;  // Raw glucose value (uncalibrated, unit same as processed)
    public float processedBloodSugar; // Final glucose value, unit: mmol/L
    public String connectCode;        // Connection code
    public long createTime;           // Glucose measurement timestamp (milliseconds)
    public int timeOffset;            // Glucose sequence number (starting from 1)
    public int measurementStatus;     // Device status at measurement time
    public float current;             // Current value
    public float temperature;         // Temperature
    public float batteryVoltage;      // Battery voltage
    /**
     * Glucose trend:
     * 1  - Steady
     * 5  - Slow rise
     * 10 - Slow fall
     * 15 - Fast rise
     * 20 - Fast fall
     */
    public int trend = 1;
}

/**
 * Device information
 */
public class CgmDeviceInfo {
    public long measurementInterval;          // Measurement interval (seconds)
    public String firmwareVersion;            // Firmware version
    public long deviceActivateTimestamp;      // Device activation timestamp (seconds)
    public int timeOffset;                    // Current maximum sequence number
    public boolean isPreheating;              // Preheating (within 60 minutes after activation)
    public boolean isInUse;                   // In use (preheating completed and not expired)
    public boolean isExpired;                 // Expired (over 15 days)
    public boolean isDeviceReset;             // Device reset (power off/restart, discarded)
    public List<DeviceAbnormalState> abnormalStates;
}
```

### Querying Historical Data

It is recommended to call this after the device is successfully connected and initial data synchronization is complete; otherwise, the local database may not contain the latest data.

```java
/**
 * Query by starting sequence number
 * @param sn         Sensor SN
 * @param indexStart Starting sequence number (starting from 1; if 0, returns empty)
 */
void getHistoryFromIndexStart(String sn, int indexStart, CgmSyncHistoryCallback callback);

/**
 * Query by time range (time in seconds)
 */
void getHistoryFromTimeRange(String sn, long startTime, long endTime, CgmSyncHistoryCallback callback);

public interface CgmSyncHistoryCallback {
    void onSyncHistorySuccess(List<CgmBloodSugar> bloodSugarData);

    void onSyncHistoryFailed(CgmError error);
}
```

### SDK Historical Data Sync Progress Callback

```java
void setCgmDeviceDataSyncProgressCallback(CgmDeviceDataSyncProgressCallback callback);

public interface CgmDeviceDataSyncProgressCallback {
    void onProgress(int progress);  // 0-100, 100 indicates sync complete or real‑time data received
}
```

### Device Binding Step Callback

This callback covers Bluetooth discovery, connection, service startup, information query, activation, and data synchronization. Suitable for showing progress during device binding.

```java
void setCgmBindStepCallback(CgmDeviceBindingStepCallback callback);

public interface CgmDeviceBindingStepCallback {
    void onResult(DeviceBindingStep step);
}

public enum DeviceBindingStep {
    DeviceSearching,           // Start searching for device
    DeviceFound,               // Device found
    DeviceNotFound,            // Device not found (timeout)
    DeviceConnecting,          // Connecting
    DeviceConnectSuccess,      // Connection successful
    DeviceConnectFail,         // Connection failed
    DeviceEnableServiceIng,    // Starting Bluetooth service
    DeviceEnableServiceSuccess,
    DeviceEnableServiceFail,
    DeviceActivating,          // Activating device
    DeviceActivationSuccess,
    DeviceActivationFail,
    DeviceHistoryDataSyncing,  // Syncing historical data
    DeviceHistoryDataSyncSuccess,
    DeviceHistoryDataSyncFail,
}
```

### Logging

During debugging, you can set a log callback to print internal SDK logs.

```java
void setCgmLogCallback(CgmLogCallback callback);

public interface CgmLogCallback {
    void onPrint(String message);
}
```

### Error Enum

```java
public enum CgmError {
    // Cloud API errors (1000-1009)
    queryNetworkError(1001, "Network error, please check network"),
    queryTimeout(1002, "Cloud request timeout"),
    queryServerError(1003, "Cloud request failed"),
    queryParamError(1004, "Parameter error"),
    queryUnauthorized(1005, "Authentication failed"),
    queryUnauthenticated(1006, "SDK not authenticated"),
    queryDeviceNotFound(1007, "Device not found"),
    queryDeviceExpired(1008, "Device expired"),
    queryAuthExpired(1009, "Authentication expired"),

    // Bluetooth scan/connection errors (2000-2099)
    bleScanError(2002, "Bluetooth scan failed"),
    bleScanTimeout(2003, "Bluetooth scan timeout"),
    bleConnectTimeout(2004, "Bluetooth connection timeout"),
    bleConnectError(2005, "Bluetooth connection failed"),
    bleMtuError(2006, "Setting MTU failed"),
    bleServerError(2007, "Bluetooth service startup failed"),
    bleWriteError(2008, "Bluetooth command write failed"),
    bleNotifyTimeout(2009, "Bluetooth response timeout"),
    bleNotifyStateError(2010, "Bluetooth response status error"),

    // Device errors (3000-3099)
    deviceSnError(3001, "SN code error"),
    deviceAbandoned(3003, "Device malfunction"),

    // Database query errors (4000-4099)
    dataDBQueryError(4001, "Database query error"),
    dataBleQueryError(4002, "Query rejected by Bluetooth"),

    unknown(-1, "Unknown error");
}
```

### SDK Usage Example

**1. Initialization (in Application)**

```java
public class BaseApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        CgmDeviceManager.getInstance().init(this);
    }
}
```

**2. Request permissions (in Activity)**

```java
public class MainActivity extends AppCompatActivity {
    private CgmPermissionHelper permissionHelper;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        permissionHelper = new CgmPermissionHelper(this);
        // Recommended one‑stop request for Bluetooth + background location
        permissionHelper.requestBleAndBackgroundPermission(new CgmPermissionCallback() {
            @Override
            public void onSuccess() {
                // Permissions granted, proceed with Bluetooth operations
            }

            @Override
            public void onError(List<String> deniedPermissions, boolean hasPermanentlyDenied) {
                // Prompt user to manually grant permissions
            }
        });
    }
}
```

**3. SDK Authentication**

```Kotlin
CgmDeviceManager.getInstance()
    .authCert("your_app_id", "your_app_secret", object : CgmAuthCallback() {
        @Override
        fun onSuccess() {
            // Authentication successful, ready to connect to device
        }

        @Override
        fun onError(error: CgmError) {
            // Handle authentication failure
        }
    });
```

**4. Set data listeners**

```kotlin
CgmDeviceManager.getInstance().setCgmDeviceStateInfoCallback(object :
    CgmDeviceStateInfoCallback {
    override fun onFailed(cgmError: CgmError) {
        // Handle data sync failure
    }

    override fun onGlucoseDataWithErrorReceived(
        isAbandoned: Boolean,
        isErrorShow: Boolean,
        abnormalStates: List<DeviceAbnormalState>,
        data: List<CgmBloodSugar>
    ) {
        // Device abnormal states and glucose data
    }

    override fun onDeviceInfoReceived(cgmDeviceInfo: CgmDeviceInfo?) {
        // Device basic information
    }

})

CgmDeviceManager.getInstance().setCgmDeviceDataSyncProgressCallback { progress ->
    // Update sync progress UI
}
```

**5. Scan and connect to device**

```Kotlin
val sn = "device SN"
// Scan and connect to device
CgmDeviceManager.getInstance().connectTargetAndStartScan(sn, false, object : CgmConnectCallback() {
    @Override
     fun onDeviceDisconnected () {
        // Handle disconnection (can start heartbeat reconnection)
    }
    @Override
   fun onSuccess () {
        // Connection successful
    }
    @Override
    fun onFailure ( error:CgmError){
        // Connection failed
    }
});
// Pass scan result to SDK for Bluetooth connection
CgmDeviceManager.getInstance().connectTargetDevice(scanResult, sn, false, object : CgmConnectCallback() {
    @Override
    fun onDeviceDisconnected () {
        // Handle disconnection (can start heartbeat reconnection)
    }
    @Override
    fun onSuccess () {
        // Connection successful
    }
    @Override
    fun onFailure ( error:CgmError){
        // Connection failed
    }
});
```

**6. Query historical data (after successful connection)**

```kotlin
CgmDeviceManager.getInstance().getHistoryFromIndexStart(sn, 1, object : CgmSyncHistoryCallback() {
    @Override
    fun onSyncHistorySuccess ( bloodSugarData:List <CgmBloodSugar>) {
        // Process historical data
    }
    @Override
   fun onSyncHistoryFailed ( error:CgmError){
    }
});
```