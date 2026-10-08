/// Semantic and UI Strings for SafePath Application
class AppStrings {
  AppStrings._();

  static const String appName = 'SafePath';
  static const String appTagline = 'Smart Blind Stick Safety System';

  // Role Selection
  static const String chooseRoleTitle = 'Choose Your Role';
  static const String chooseRoleSubtitle =
      'Select how you will be using this SafePath application.';
  static const String roleBlindUser = 'I AM A BLIND STICK USER';
  static const String roleBlindUserDesc =
      'High contrast, voice alerts, direct ESP32 stick connection, and instant SOS.';
  static const String roleCaretaker = 'I AM A CARETAKER';
  static const String roleCaretakerDesc =
      'Live map tracking, stick telemetry monitoring, and emergency notifications.';

  // Stick Connection States
  static const String stickConnected = 'Stick: CONNECTED';
  static const String stickDisconnected = 'Stick: DISCONNECTED';
  static const String stickReconnecting = 'Stick: RECONNECTING...';
  static const String stickOffline = 'Stick: OFFLINE';

  // Telemetry Labels
  static const String ultrasonicTitle = 'Obstacle Sensors';
  static const String leftSensor = 'LEFT';
  static const String middleSensor = 'MIDDLE';
  static const String rightSensor = 'RIGHT';

  static const String statusSafe = 'Safe';
  static const String statusDanger = 'Danger';
  static const String statusUnavailable = 'Unavailable';

  static const String mpuTitle = 'Motion & Fall Monitor';
  static const String accelerationLabel = 'Acceleration';
  static const String tiltLabel = 'Tilt';
  static const String fallNormal = 'NORMAL';
  static const String fallDetected = 'FALL DETECTED';

  // SOS Emergency
  static const String sosTitle = '🚨 EMERGENCY SOS ACTIVE 🚨';
  static const String sosSubtitle = 'The SafePath stick has triggered an emergency!';
  static const String sosClearButton = 'CLEAR & RESET SOS';
  static const String sosConfirmClear = 'Are you sure you want to clear the SOS state on the stick?';

  // Emergency Contact
  static const String emergencyContactTitle = 'Emergency Contact';
  static const String addContact = 'Add Emergency Contact';
  static const String editContact = 'Edit Emergency Contact';
  static const String contactName = 'Full Name';
  static const String contactPhone = 'Phone Number';
  static const String saveContact = 'Save Contact';
  static const String deleteContact = 'Delete Contact';
  static const String testAlert = 'Send Test Alert';
  static const String noContactConfigured = 'No emergency contact configured yet.';

  // Errors
  static const String errEsp32NotFound =
      'ESP32 not found. Connect your phone to Wi-Fi SSID "SafePath_SmartStick".';
  static const String errTimeout = 'Communication timed out with the stick.';
  static const String errInvalidResponse = 'Received invalid data from the stick.';
  static const String errGpsDenied = 'Location permission is required for emergency dispatch.';
}
