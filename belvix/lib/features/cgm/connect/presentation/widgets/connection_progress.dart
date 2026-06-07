import '../../../session/cgm_session_state.dart';

/// Per-row state in the connect checklist.
enum CgmStepState { pending, active, done, failed }

/// One row in the connect checklist.
class CgmConnectStep {
  final String label;
  final CgmStepState state;

  const CgmConnectStep(
    this.label,
    this.state,
  );
}

/// The five connection phases the SDK walks through, in order. Each maps to
/// a group of `DeviceBindingStep`s (see memory: eaglenos-sdk-bind-steps).
enum CgmConnectPhase {
  find,
  connect,
  service,
  activate,
  sync,
}

/// Outcome-style labels so the checklist reads as items ticking off.
const _phaseLabels = <String>[
  "Sensor found",
  "Sensor connected",
  "Service started",
  "Sensor activated",
  "Readings synced",
];

/// What we say under the headline while a given phase is in progress.
const _phaseDetail = <String>[
  "Looking for your sensor nearby…",
  "Connecting to your sensor…",
  "Starting the sensor service…",
  "Activating your sensor…",
  "Syncing your readings…",
];

/// A derived, render-ready view of where the connection is. Built purely from
/// the session [CGMConnectionStatus] + the SDK's last `bindStep`, so the UI can
/// show the same calm step-by-step checklist the reference app does without the
/// state machine having to model every micro-step.
class CgmConnectionProgress {
  final List<CgmConnectStep> steps;

  /// Sync finished / live data flowing — ready to move to the dashboard.
  final bool isComplete;

  /// A user-actionable hard stop (BT off, permissions, auth, expired, …).
  final bool isFatal;

  /// Still hunting for the sensor — the calm "keep looking" state. Never an
  /// error, even when the SDK briefly reports DeviceNotFound mid-retry.
  final bool isSearching;

  final String headline;
  final String detail;

  const CgmConnectionProgress({
    required this.steps,
    required this.isComplete,
    required this.isFatal,
    required this.isSearching,
    required this.headline,
    required this.detail,
  });

  factory CgmConnectionProgress.from({
    required CGMConnectionStatus status,
    String? bindStep,
    Duration elapsed = Duration.zero,
  }) {
    final fatal = _isFatalStatus(status);

    // doneUpTo = number of fully-completed phases (0..5)
    // active    = phase currently in progress, or -1
    // failed    = phase that failed, or -1
    var doneUpTo = 0;
    var active = -1;
    var failed = -1;

    // 1) Prefer the granular bind step — it's the most precise signal.
    switch (bindStep) {
      case "DeviceSearching":
      case "DeviceNotFound": // still retrying — keep it calm, not a failure
        doneUpTo = 0;
        active = 0;
        break;
      case "DeviceFound":
      case "DeviceConnecting":
        doneUpTo = 1;
        active = 1;
        break;
      case "DeviceConnectSuccess":
        doneUpTo = 2;
        active = 2;
        break;
      case "DeviceConnectFail":
        doneUpTo = 1;
        failed = 1;
        break;
      case "DeviceEnableServiceIng":
        doneUpTo = 2;
        active = 2;
        break;
      case "DeviceEnableServiceSuccess":
        doneUpTo = 3;
        active = 3;
        break;
      case "DeviceEnableServiceFail":
        doneUpTo = 2;
        failed = 2;
        break;
      case "DeviceActivating":
        doneUpTo = 3;
        active = 3;
        break;
      case "DeviceActivationSuccess":
        doneUpTo = 4;
        active = 4;
        break;
      case "DeviceActivationFail":
        doneUpTo = 3;
        failed = 3;
        break;
      case "DeviceHistoryDataSyncing":
        doneUpTo = 4;
        active = 4;
        break;
      case "DeviceHistoryDataSyncSuccess":
        doneUpTo = 5;
        break;
      case "DeviceHistoryDataSyncFail":
        doneUpTo = 4;
        failed = 4;
        break;
    }

    // 2) Fold in the coarse status so we still progress when a Success step
    //    is skipped, and so completion (active/syncing) always wins.
    final fromStatus = _statusProgress(status);
    if (fromStatus.doneUpTo > doneUpTo) {
      doneUpTo = fromStatus.doneUpTo;
      // Adopt the status' active phase only if the bind step didn't give us a
      // more advanced one.
      if (active < fromStatus.active) active = fromStatus.active;
    }
    if (active < 0 && failed < 0) active = fromStatus.active;

    final complete = doneUpTo >= 5 ||
        status == CGMConnectionStatus.active ||
        status == CGMConnectionStatus.syncing;

    // Build the rows.
    final steps = <CgmConnectStep>[];
    for (var i = 0; i < _phaseLabels.length; i++) {
      CgmStepState s;
      if (complete || i < doneUpTo) {
        s = CgmStepState.done;
      } else if (i == failed) {
        s = CgmStepState.failed;
      } else if (i == active && !fatal) {
        s = CgmStepState.active;
      } else if (i == active && fatal) {
        // Fatal stop mid-phase — mark the stuck phase as failed.
        s = CgmStepState.failed;
      } else {
        s = CgmStepState.pending;
      }
      steps.add(CgmConnectStep(_phaseLabels[i], s));
    }

    final searching = !fatal && !complete && active == 0;

    return CgmConnectionProgress(
      steps: steps,
      isComplete: complete,
      isFatal: fatal,
      isSearching: searching,
      headline: _headline(
        status: status,
        complete: complete,
        fatal: fatal,
        searching: searching,
      ),
      detail: _detail(
        status: status,
        complete: complete,
        fatal: fatal,
        searching: searching,
        active: active,
        elapsed: elapsed,
      ),
    );
  }

  static bool _isFatalStatus(
    CGMConnectionStatus status,
  ) {
    switch (status) {
      case CGMConnectionStatus.failed:
      case CGMConnectionStatus.authFailed:
      case CGMConnectionStatus.permissionsDenied:
      case CGMConnectionStatus.bluetoothOff:
      case CGMConnectionStatus.expired:
      case CGMConnectionStatus.malfunction:
        return true;
      default:
        return false;
    }
  }

  static ({int doneUpTo, int active}) _statusProgress(
    CGMConnectionStatus status,
  ) {
    switch (status) {
      case CGMConnectionStatus.authenticating:
      case CGMConnectionStatus.reconnecting:
      case CGMConnectionStatus.searching:
      case CGMConnectionStatus.outOfRange:
        return (doneUpTo: 0, active: 0);
      case CGMConnectionStatus.connecting:
        return (doneUpTo: 1, active: 1);
      case CGMConnectionStatus.warmup:
        return (doneUpTo: 3, active: 3);
      case CGMConnectionStatus.syncing:
        return (doneUpTo: 4, active: 4);
      case CGMConnectionStatus.active:
        return (doneUpTo: 5, active: -1);
      default:
        return (doneUpTo: 0, active: -1);
    }
  }

  static String _headline({
    required CGMConnectionStatus status,
    required bool complete,
    required bool fatal,
    required bool searching,
  }) {
    if (complete) return "You're all set";
    if (fatal) {
      switch (status) {
        case CGMConnectionStatus.bluetoothOff:
          return "Bluetooth is off";
        case CGMConnectionStatus.permissionsDenied:
          return "Permission needed";
        case CGMConnectionStatus.authFailed:
          return "Couldn't authorise";
        case CGMConnectionStatus.expired:
          return "Sensor expired";
        case CGMConnectionStatus.malfunction:
          return "Sensor problem";
        default:
          return "Couldn't connect";
      }
    }
    if (searching) return "Finding your sensor";
    return "Setting up your sensor";
  }

  static String _detail({
    required CGMConnectionStatus status,
    required bool complete,
    required bool fatal,
    required bool searching,
    required int active,
    required Duration elapsed,
  }) {
    if (complete) return "Opening your dashboard…";
    if (fatal) {
      switch (status) {
        case CGMConnectionStatus.bluetoothOff:
          return "Turn on Bluetooth to finish pairing.";
        case CGMConnectionStatus.permissionsDenied:
          return "Allow Bluetooth (and nearby devices) to continue.";
        case CGMConnectionStatus.authFailed:
          return "We couldn't verify the sensor SDK. Please try again.";
        case CGMConnectionStatus.expired:
          return "This sensor has reached the end of its life. Replace it to continue.";
        case CGMConnectionStatus.malfunction:
          return "This sensor reported a fault. Please replace it.";
        default:
          return "Something went wrong. You can try again.";
      }
    }
    if (searching) {
      // Escalate gently the longer it takes, without ever looking broken.
      if (elapsed.inSeconds >= 20) {
        return "Still looking — keep your phone right next to the sensor.";
      }
      return "Hold your phone close to the sensor. This usually takes a few seconds.";
    }
    if (active >= 0 && active < _phaseDetail.length) {
      return _phaseDetail[active];
    }
    return "Hang tight while we set up your sensor.";
  }
}
