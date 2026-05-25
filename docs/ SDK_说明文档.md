# eagleSDKDemo

## 一、介绍

本SDK仅针对获得授权的APP开放使用，未授权APP无法调用功能；使用SDK前必须完成**鉴权认证**，否则无法正常使用全部功能。

该SDK支持接收晶捷动态血糖仪的血糖数据，仅需调用方法并传递探头SN号，即可实现蓝牙连接与数据接收。

**所有公开方法均通过 `CgmDeviceManager.getInstance()` 单例调用。**

## 二、权限声明

SDK在清单文件中声明的权限，有以下内容：

```xml
<!-- ************************ 声明蓝牙硬件，没有蓝牙的手机无法安装使用 ******************** -->
<uses-feature
    android:name="android.hardware.bluetooth" /><!-- ************************ 蓝牙权限，安卓11及以下 ******************** -->
<uses-permission android:name="android.permission.BLUETOOTH"
android:maxSdkVersion="30" /><uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
android:maxSdkVersion="30" /><!-- ************************ 定位权限，蓝牙扫描需要用到，安卓11及以下 ******************** -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
android:maxSdkVersion="30" /><uses-permission
android:name="android.permission.ACCESS_COARSE_LOCATION"
android:maxSdkVersion="30" /><uses-permission
android:name="android.permission.ACCESS_BACKGROUND_LOCATION"
android:maxSdkVersion="30" /><!-- ************************ 蓝牙权限，安卓12及以上 ******************** -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
android:usesPermissionFlags="neverForLocation" /><uses-permission
android:name="android.permission.BLUETOOTH_CONNECT" /><uses-permission
android:name="android.permission.ACCESS_NETWORK_STATE" /><uses-permission
android:name="android.permission.SCHEDULE_EXACT_ALARM" /><uses-permission
android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```

**核心权限说明**：

- 蓝牙扫描与连接必须拥有 `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT`（Android 12+）或 `BLUETOOTH` /
  `BLUETOOTH_ADMIN`（Android 11-）。
- 蓝牙扫描需要位置权限，Android 11- 必须申请 `ACCESS_FINE_LOCATION` 或 `ACCESS_COARSE_LOCATION`。
- 后台扫描（Android 10-11）需要 `ACCESS_BACKGROUND_LOCATION`。
- 若APP不想声明某些非必要权限（如闹钟、忽略电池优化），可按如下方式移除：
  ```xml
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" tools:node="remove" />
  ```

## 三、安装教程

1. 将 `bleHealth-release.aar` 文件复制到APP模块的 `libs` 目录下（若无libs目录则手动创建）；
2. 在APP模块的 `build.gradle.kts` 文件中添加依赖配置：
   ```kotlin
   implementation(files("libs/bleHealth-release.aar"))
   ```

## 四、初始化

在自定义 `Application` 中调用初始化方法，全局初始化SDK（仅需调用一次）：

```java
/**
 * 初始化SDK
 * 建议在Application的onCreate()中调用
 * @param context application
 */
void init(Application context);
```

示例：

```java
public class MyApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        CgmDeviceManager.getInstance().init(this);
    }
}
```

## 五、SDK鉴权认证

**核心要求**：SDK必须完成鉴权后，才能正常使用所有功能。appId和appSecret需向SDK提供方申请获取。

```java
/**
 * 鉴权认证
 * @param appId     申请SDK得到的参数1
 * @param appSecret 申请SDK得到的参数2
 * @param callback  鉴权的回调
 */
void authCert(String appId, String appSecret, CgmAuthCallback callback);

/**
 * 鉴权回调
 */
public interface CgmAuthCallback {
    void onSuccess();

    void onError(CgmError error);
}

/**
 * 判断SDK是否已鉴权
 */
boolean checkAuthorized();
```

## 六、使用说明

### 重要注意事项

蓝牙相关敏感权限（如蓝牙扫描、连接、定位），需由**APP自行完成动态申请**，SDK不处理权限申请逻辑。

### 权限处理

SDK提供了权限申请的工具类 `CgmPermissionHelper`，需传入 `ComponentActivity` 实例。

```java
CgmPermissionHelper cgmPermissionHelper = new CgmPermissionHelper(this);  // this为ComponentActivity实例

/**
 * 获取蓝牙必备权限（全版本适配）
 */
String[] getBluetoothPermissions();

/**
 * 获取普通定位权限
 */
String[] getLocationPermissions();

/**
 * 获取后台定位权限（仅 Android 10-11 需要）
 */
String[] getBackgroundLocationPermissions();

/**
 * 检查一组权限是否全部授予
 */
boolean hasPermissions(String[] permissions);

/**
 * 检查一组权限中是否存在【永久拒绝】的权限
 */
boolean hasPermanentlyDenied(String[] permissions);

/**
 * 申请蓝牙权限（自动包含旧版定位）
 */
void requestBluetoothPermission(CgmPermissionCallback callback);

/**
 * 申请后台定位权限（优化逻辑）
 * 解决：没有普通定位权限时，先申请定位，再申请后台
 */
void requestBackgroundLocationPermission(CgmPermissionCallback callback);

/**
 * 合并申请：蓝牙 + 后台定位（推荐使用，一步到位）
 */
void requestBleAndBackgroundPermission(CgmPermissionCallback callback);

/**
 * 申请忽略电池优化权限（引导用户到系统设置页面）
 * 注意：APP最好申请该权限，防止APP被系统限制后台运行
 */
void requestIgnoreBatteryOptimization(CgmPermissionCallback callback);
```

**权限回调接口定义**：

```java
public interface CgmPermissionCallback {
    //全部授权
    void onAllGranted();

    //权限被拒绝
    void onDenied();

    //权限被永久拒绝
    void onPermanentlyDenied();
}
```

### 蓝牙扫描

- 扫描服务UUID：`0000000a-0000-1000-8000-00805f9b34fb`（APP可自定义扫描逻辑）

```java
/**
 * 开启蓝牙扫描
 */
void startScanBluetooth(CgmScanCallback callBack);

/**
 * 蓝牙扫描的回调方法
 */
public interface CgmScanCallback {
    void onScanResult(int callbackType, ScanResult result);

    void onScanFailed(int errorCode, String message);
}

/**
 * 结束蓝牙扫描
 */
void stopScanBluetooth();
```

### 连接蓝牙设备

- 蓝牙自动重连在高版本中不生效，建议APP自行处理蓝牙断连重连的逻辑。

```java
/**
 * 扫描并且连接设备，扫描时间最多30秒，30秒后蓝牙扫描自动停止
 * @param sn            探头的SN号
 * @param isAutoConnect 是否自动连接（高版本基本无效，建议传false）
 * @param callback      连接回调方法
 */
void connectTargetAndStartScan(String sn, boolean isAutoConnect, CgmConnectCallback callback);

/**
 * 连接设备
 * @param scanResult    蓝牙扫描结果
 * @param sn            探头的SN编码
 * @param isAutoConnect 是否自动连接（建议传false）
 * @param callback      连接回调方法
 */
void connectTargetDevice(ScanResult scanResult, String sn, boolean isAutoConnect, CgmConnectCallback callback);

/**
 * 断开设备的连接
 */
void disconnectDevice();

/**
 * 设备连接状态
 */
boolean isConnected();

/**
 * 动态血糖仪设备连接的回调状态接口
 */
public interface CgmConnectCallback {
    void onDeviceDisconnected();

    void onSuccess();

    void onFailure(CgmError error);
}
```

### 蓝牙设备断连重连

SDK虽然提供了自动重连的参数，但该参数在安卓高版本基本无效，建议APP定时检验或者开启扫描将扫描结果传递给SDK。SDK提供定时心跳的工具类
`CgmHeartbeatTimerUtil`（单例）。

**清单文件注册**（必须）：

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
 * 启动心跳任务，周期性运行，每次运行间隔5分钟，每次运行30秒
 * 调用该方法前，必须在清单文件注册上述两个Receiver
 * 获取实例：CgmHeartbeatTimerUtil.INSTANCE
 */
void startHeartbeat(Context context, CgmHeartbeatCallback cgmHeartbeatCallback);

/**
 * 停止心跳任务
 */
void stopHeartbeat();

/**
 * 心跳回调
 */
public interface CgmHeartbeatCallback {
    /**
     * 心跳任务开始，每隔5分钟执行一次，可在此执行蓝牙扫描重连
     */
    void onHeartbeatStart();

    /**
     * 心跳任务开始后的30秒回调，应在此停止蓝牙扫描，防止长时间扫描
     */
    void onHeartbeatStop();
}
```

示例（Kotlin）：

```kotlin
CgmHeartbeatTimerUtil.getInstance().startHeartbeat(mContext, object : CgmHeartbeatCallback {
    override fun onHeartbeatStart() {
        // 开始扫描
        CgmDeviceManager.getInstance().startScanBluetooth(object : DeviceScanCallback {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                // 发现目标设备后连接
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

### 设备信息与血糖数据的回调

```java
/**
 * 设置设备状态、异常信息、血糖数据的监听
 */
void setCgmDeviceStateInfoCallback(CgmDeviceStateInfoCallback callback);

/**
 * 动态血糖仪（CGM）设备状态与信息回调接口
 */
public interface CgmDeviceStateInfoCallback {
    void onFailed(CgmError error);

    /**
     * @param isAbandoned    设备已损坏，无法继续使用
     * @param isErrorShow    设备异常，可继续使用，需提示用户
     * @param abnormalStates 设备异常状态枚举列表
     * @param bloodSugars    实时同步接收的血糖数据（包含实时数据及正在同步的历史数据）
     *                       已同步完成的历史数据可通过getHistoryFromIndexStart获取
     */
    void onGlucoseDataWithErrorReceived(boolean isAbandoned, boolean isErrorShow,
                                        List<DeviceAbnormalState> abnormalStates,
                                        List<CgmBloodSugar> bloodSugars);

    /**
     * 设备信息回调（连接成功后返回激活时间、序列号、固件版本、测量间隔、设备状态等）
     */
    void onDeviceInfoReceived(CgmDeviceInfo cgmDeviceInfo);
}

/**
 * 设备异常状态枚举
 */
public enum DeviceAbnormalState {
    LowBattery(0),            // 设备电量低
    TemperatureTooHigh(1),    // 设备温度过高
    TemperatureTooLow(2),     // 设备温度过低
    AfeAbnormal(3),           // AFE异常
    CurrentInvalid(4),        // 设备电流过大或过小失效
    GlucoseChangeTooFast(5),  // 血糖变化过快失效
    StateReserve1(6), StateReserve2(7),
    BatteryReset(99);         // 设备电池复位（设备断电重启，之后只能废弃）
}

/**
 * 血糖数据模型
 */
public class CgmBloodSugar {
    public float originalBloodSugar;  // 原始血糖值（未经校准，单位与processed相同）
    public float processedBloodSugar; // 最终血糖值，单位：mmol/L
    public String connectCode;        // 连接码
    public long createTime;           // 血糖测量时间（毫秒时间戳）
    public int timeOffset;            // 血糖序列号（从1开始递增）
    public int measurementStatus;     // 测量时设备状态
    public float current;             // 电流值
    public float temperature;         // 温度
    public float batteryVoltage;      // 电池电压
    /**
     * 血糖趋势：
     * 1  - 平稳
     * 5  - 缓慢上升
     * 10 - 缓慢下降
     * 15 - 快速上升
     * 20 - 快速下降
     */
    public int trend = 1;
}

/**
 * 设备信息
 */
public class CgmDeviceInfo {
    public long measurementInterval;          // 测量间隔（秒）
    public String firmwareVersion;            // 固件版本
    public long deviceActivateTimestamp;      // 设备激活时间戳（秒）
    public int timeOffset;                    // 当前最大序列号
    public boolean isPreheating;              // 预热中（激活后60分钟内）
    public boolean isInUse;                   // 使用中（预热完成且未过期）
    public boolean isExpired;                 // 已过期（超过15天）
    public boolean isDeviceReset;             // 设备重置（断电重启，已废弃）
    public List<DeviceAbnormalState> abnormalStates;
}
```

### 历史数据的查询

建议在设备连接成功并完成初次数据同步后调用，否则本地数据库可能不含最新数据。

```java
/**
 * 通过起始位置的序列号进行查询
 * @param sn         探头的SN编码
 * @param indexStart 起始序列号（从1开始，若传0则返回空）
 */
void getHistoryFromIndexStart(String sn, int indexStart, CgmSyncHistoryCallback callback);

/**
 * 通过时间范围进行查询（时间单位为秒）
 */
void getHistoryFromTimeRange(String sn, long startTime, long endTime, CgmSyncHistoryCallback callback);

public interface CgmSyncHistoryCallback {
    void onSyncHistorySuccess(List<CgmBloodSugar> bloodSugarData);

    void onSyncHistoryFailed(CgmError error);
}
```

### SDK同步历史数据进度回调

```java
void setCgmDeviceDataSyncProgressCallback(CgmDeviceDataSyncProgressCallback callback);

public interface CgmDeviceDataSyncProgressCallback {
    void onProgress(int progress);  // 0-100，同步完成或实时数据时触发100
}
```

### 设备流程回调

该流程包含蓝牙搜索、连接、服务启动、信息查询、激活、数据同步。适合在绑定设备时展示进度。

```java
void setCgmBindStepCallback(CgmDeviceBindingStepCallback callback);

public interface CgmDeviceBindingStepCallback {
    void onResult(DeviceBindingStep step);
}

public enum DeviceBindingStep {
    DeviceSearching,           // 开始搜索设备
    DeviceFound,               // 已找到设备
    DeviceNotFound,            // 未发现设备（超时）
    DeviceConnecting,          // 连接中
    DeviceConnectSuccess,      // 连接成功
    DeviceConnectFail,         // 连接失败
    DeviceEnableServiceIng,    // 启动蓝牙服务中
    DeviceEnableServiceSuccess,
    DeviceEnableServiceFail,
    DeviceActivating,          // 激活设备中
    DeviceActivationSuccess,
    DeviceActivationFail,
    DeviceHistoryDataSyncing,  // 同步历史数据中
    DeviceHistoryDataSyncSuccess,
    DeviceHistoryDataSyncFail,
}
```

### 日志打印

调试阶段可设置日志回调打印SDK内部日志。

```java
void setCgmLogCallback(CgmLogCallback callback);

public interface CgmLogCallback {
    void onPrint(String message);
}
```

### 异常枚举

```java
public enum CgmError {
    // 云端接口异常 (1000-1009)
    queryNetworkError(1001, "网络异常，请检查网络"),
    queryTimeout(1002, "云端请求超时"),
    queryServerError(1003, "云端请求失败"),
    queryParamError(1004, "参数异常"),
    queryUnauthorized(1005, "鉴权失败"),
    queryUnauthenticated(1006, "SDK未鉴权"),
    queryDeviceNotFound(1007, "未找到设备"),
    queryDeviceExpired(1008, "设备已过期"),
    queryAuthExpired(1009, "鉴权已失效"),

    // 蓝牙扫描/连接异常 (2000-2099)
    bleScanError(2002, "蓝牙扫描失败"),
    bleScanTimeout(2003, "蓝牙扫描超时"),
    bleConnectTimeout(2004, "蓝牙连接超时"),
    bleConnectError(2005, "蓝牙连接失败"),
    bleMtuError(2006, "设置MTU失败"),
    bleServerError(2007, "蓝牙服务启动失败"),
    bleWriteError(2008, "蓝牙命令写入失败"),
    bleNotifyTimeout(2009, "蓝牙回应超时"),
    bleNotifyStateError(2010, "蓝牙回应状态异常"),

    // 设备异常 (3000-3099)
    deviceSnError(3001, "SN编码异常"),
    deviceAbandoned(3003, "设备故障"),

    // 数据库查询异常 (4000-4099)
    dataDBQueryError(4001, "数据库的数据查询异常"),
    dataBleQueryError(4002, "查询数据，蓝牙请求拒绝"),

    unknown(-1, "未知错误");
}
```

### SDK使用实例

**1. 初始化（Application中）**

```java
public class BaseApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        CgmDeviceManager.getInstance().init(this);
    }
}
```

**2. 申请权限（Activity中）**

```java
public class MainActivity extends AppCompatActivity {
    private CgmPermissionHelper permissionHelper;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        permissionHelper = new CgmPermissionHelper(this);
        // 推荐一步到位申请蓝牙+后台定位权限
        permissionHelper.requestBleAndBackgroundPermission(new CgmPermissionCallback() {
            @Override
            public void onSuccess() {
                // 权限已授予，可进行蓝牙操作
            }

            @Override
            public void onError(List<String> deniedPermissions, boolean hasPermanentlyDenied) {
                // 提示用户手动授权
            }
        });
    }
}
```

**3. SDK鉴权**

```Kotlin
CgmDeviceManager.getInstance()
    .authCert("your_app_id", "your_app_secret", object : CgmAuthCallback() {
        @Override
        fun onSuccess() {
            // 鉴权成功，可开始连接设备
        }

        @Override
        fun onError(error: CgmError) {
            // 处理鉴权失败
        }
    });
```

**4. 设置数据监听**

```kotlin
CgmDeviceManager.getInstance().setCgmDeviceStateInfoCallback(object :
    CgmDeviceStateInfoCallback {
    override fun onFailed(cgmError: CgmError) {
        //同步数据的失败的异常情况处理
    }

    override fun onGlucoseDataWithErrorReceived(
        isAbandoned: Boolean,
        isErrorShow: Boolean,
        abnormalStates: List<DeviceAbnormalState>,
        data: List<CgmBloodSugar>
    ) {
        //设备异常状态和血糖数据
    }

    override fun onDeviceInfoReceived(cgmDeviceInfo: CgmDeviceInfo?) {
        //设备基本信息
    }

})

CgmDeviceManager.getInstance().setCgmDeviceDataSyncProgressCallback {progress ->
    // 更新同步进度UI
}
```

**5. 扫描并连接设备**

```Kotlin
val sn = "设备SN号"
//扫描并且连接设备
CgmDeviceManager.getInstance().connectTargetAndStartScan(sn, false,object :CgmConnectCallback() {
    @Override
     fun onDeviceDisconnected () {
        // 处理断连（可启动心跳重连）
    }
    @Override
   fun onSuccess () {
        // 连接成功
    }
    @Override
    fun onFailure ( error:CgmError){
        // 连接失败
    }
});
//将扫描结果传递给SDK，进行蓝牙连接
CgmDeviceManager.getInstance().connectTargetDevice(scanResult,sn, false,object :CgmConnectCallback() {
    @Override
    fun onDeviceDisconnected () {
        // 处理断连（可启动心跳重连）
    }
    @Override
    fun onSuccess () {
        // 连接成功
    }
    @Override
    fun onFailure ( error:CgmError){
        // 连接失败
    }
});
```

**6. 查询历史数据（连接成功后）**

```kotlin
CgmDeviceManager.getInstance().getHistoryFromIndexStart(sn, 1,object :CgmSyncHistoryCallback() {
    @Override
    fun onSyncHistorySuccess ( bloodSugarData:List <CgmBloodSugar>) {
        // 处理历史数据
    }
    @Override
   fun onSyncHistoryFailed ( error:CgmError){
    }
});
```

