import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/features/cgm/connect/presentation/widgets/connection_progress.dart';
import 'package:mobile_app/features/cgm/session/cgm_session_state.dart';

CgmConnectionProgress _progress({
  required CGMConnectionStatus status,
  String? bindStep,
  Duration elapsed = Duration.zero,
}) =>
    CgmConnectionProgress.from(
      status: status,
      bindStep: bindStep,
      elapsed: elapsed,
    );

void main() {
  group('CgmConnectionProgress', () {
    test('searching: first step active, rest pending, calm', () {
      final p = _progress(
        status: CGMConnectionStatus.searching,
        bindStep: 'DeviceSearching',
      );

      expect(p.isSearching, isTrue);
      expect(p.isFatal, isFalse);
      expect(p.isComplete, isFalse);
      expect(p.steps.first.state, CgmStepState.active);
      expect(
        p.steps.skip(1).every((s) => s.state == CgmStepState.pending),
        isTrue,
      );
    });

    test('DeviceNotFound stays a calm search, never a failure', () {
      final p = _progress(
        status: CGMConnectionStatus.outOfRange,
        bindStep: 'DeviceNotFound',
      );

      expect(p.isFatal, isFalse);
      expect(p.isSearching, isTrue);
      expect(
        p.steps.any((s) => s.state == CgmStepState.failed),
        isFalse,
      );
    });

    test('searching copy escalates after 20s', () {
      final short = _progress(
        status: CGMConnectionStatus.searching,
        bindStep: 'DeviceSearching',
        elapsed: const Duration(seconds: 5),
      );
      final long = _progress(
        status: CGMConnectionStatus.searching,
        bindStep: 'DeviceSearching',
        elapsed: const Duration(seconds: 25),
      );

      expect(short.detail == long.detail, isFalse);
    });

    test('connect success ticks off found + connected, service active', () {
      final p = _progress(
        status: CGMConnectionStatus.connecting,
        bindStep: 'DeviceConnectSuccess',
      );

      expect(p.steps[0].state, CgmStepState.done); // found
      expect(p.steps[1].state, CgmStepState.done); // connected
      expect(p.steps[2].state, CgmStepState.active); // service
      expect(p.steps[3].state, CgmStepState.pending);
    });

    test('history syncing: first four done, sync active', () {
      final p = _progress(
        status: CGMConnectionStatus.syncing,
        bindStep: 'DeviceHistoryDataSyncing',
      );

      for (var i = 0; i < 4; i++) {
        expect(p.steps[i].state, CgmStepState.done);
      }
      // syncing status marks completion-eligible, so the last row reads done
      // and we treat the session as ready to advance.
      expect(p.isComplete, isTrue);
    });

    test('active status is complete with every step done', () {
      final p = _progress(
        status: CGMConnectionStatus.active,
        bindStep: 'DeviceHistoryDataSyncSuccess',
      );

      expect(p.isComplete, isTrue);
      expect(
        p.steps.every((s) => s.state == CgmStepState.done),
        isTrue,
      );
    });

    test('a mid-flow connect failure marks that step failed, not fatal-only', () {
      final p = _progress(
        status: CGMConnectionStatus.failed,
        bindStep: 'DeviceConnectFail',
      );

      expect(p.isFatal, isTrue);
      expect(p.steps[1].state, CgmStepState.failed);
    });

    test('bluetooth off and permissions are fatal', () {
      expect(
        _progress(status: CGMConnectionStatus.bluetoothOff).isFatal,
        isTrue,
      );
      expect(
        _progress(status: CGMConnectionStatus.permissionsDenied).isFatal,
        isTrue,
      );
    });
  });
}
