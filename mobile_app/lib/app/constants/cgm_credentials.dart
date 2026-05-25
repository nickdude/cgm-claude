/// Eaglenos CGM SDK credentials.
///
/// Override at launch with:
///   --dart-define=CGM_APP_ID=...
///   --dart-define=CGM_APP_SECRET=...
///
/// The defaults below are the development pair currently in use.
class CgmCredentials {
  static const String appId =
      String.fromEnvironment(
    "CGM_APP_ID",
    defaultValue: "642434",
  );

  static const String appSecret =
      String.fromEnvironment(
    "CGM_APP_SECRET",
    defaultValue:
        "wtrWYS8bnRTxssyNwbbwsyNYccpYlkP8",
  );

  static bool get isConfigured =>
      appId.isNotEmpty &&
      appSecret.isNotEmpty;
}
