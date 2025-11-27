/// SIP Configuration
/// Contains static configuration values for SIP registration
class SipConfig {
  // SIP Username (Display name)
  static String sipUsername = "";

  // SIP Auth Username (usually same as username)
  static String get sipAuthUsername => sipUsername;

  // SIP Password (required for authentication)
  static const String sipPassword = "Sahad";

  // SIP Domain / Host
  static const String sipDomain = "syscarecc.systech.ae";

  // Profile name (not important for SIP)
  static String get profileName => sipUsername;

  // WebSocket Host
  static const String websocketHost = "syscarecc.systech.ae";

  // WebSocket Port
  static const String websocketPort = "7443";

  // WebSocket Path
  static const String websocketPath = "/ws";

  // Call Waiting enabled?
  static const String callWaiting = "yes";

  // Anonymous call? (0 = no)
  static const String anonymous = "0";

  // User unique ID from server
  static const String uuid = "9e047376-7a86-4193-85cf-4d0b0d9d60f6";

  // Computed values

  /// Full WebSocket URL
  /// Format: wss://host:port/path
  static String get websocketUrl =>
      "wss://$websocketHost:$websocketPort$websocketPath";

  /// Full SIP URI
  /// Format: sip:username@domain
  static String get sipUri => "sip:$sipUsername@$sipDomain";

  /// Call waiting enabled as boolean
  static bool get isCallWaitingEnabled => callWaiting.toLowerCase() == "yes";

  /// Anonymous call as boolean
  static bool get isAnonymous => anonymous == "1";
}
