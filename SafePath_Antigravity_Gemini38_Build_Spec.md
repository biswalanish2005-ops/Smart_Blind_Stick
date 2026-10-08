# SAFEPATH SMART BLIND STICK — ANTIGRAVITY / GEMINI 3.8 BUILD SPEC

## 0. MASTER INSTRUCTION

You are building a **real, production-oriented Flutter Android application** for the SafePath Smart Blind Stick.

Target environment:
- Flutter
- Android
- Development/build using Antigravity with Gemini 3.8
- Real ESP32 hardware
- Real MPU6050
- Real 3 × HC-SR04 ultrasonic sensors
- Real SOS button
- Real phone GPS
- Real Firebase/cloud synchronization
- No simulation
- No fake sensor values
- No mock GPS
- No placeholder telemetry in the final working app
- No demo-only screens
- The final APK must communicate with real hardware and real cloud data.

The application has two modes selected on the first screen:

1. **BLIND STICK USER**
2. **CARETAKER**

Build these as two genuinely different interfaces optimized for their respective users.

---

# 1. SYSTEM ARCHITECTURE

The system consists of:

```text
                    ┌─────────────────────┐
                    │     ESP32 Stick     │
                    │                     │
                    │  3× Ultrasonic      │
                    │  MPU6050             │
                    │  SOS Button          │
                    │  Buzzer + LED        │
                    └──────────┬──────────┘
                               │
                     Local Wi-Fi / HTTP
                               │
                               ▼
                    ┌─────────────────────┐
                    │  Blind User Phone   │
                    │                     │
                    │ Flutter App         │
                    │ ESP32 telemetry     │
                    │ GPS location        │
                    │ Emergency contact   │
                    └──────────┬──────────┘
                               │
                         Internet
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Firebase Backend    │
                    │                     │
                    │ Auth                │
                    │ Firestore           │
                    │ FCM                 │
                    │ Cloud Functions     │
                    └──────────┬──────────┘
                               │
                         Internet
                               │
                               ▼
                    ┌─────────────────────┐
                    │ Caretaker Phone     │
                    │                     │
                    │ Live map             │
                    │ Stick status        │
                    │ Sensor telemetry     │
                    │ SOS state            │
                    └─────────────────────┘
```

### Critical architecture rule

The ESP32 does **not** have GPS.

Therefore:

```text
ESP32 detects fall/SOS
       ↓
Blind user's phone receives SOS
       ↓
Blind user's phone obtains GPS
       ↓
Phone sends location + SOS to Firebase
       ↓
Caretaker receives live alert/location
```

Do not incorrectly attempt to obtain GPS from the ESP32.

---

# 2. FIRST SCREEN — ROLE SELECTION

On first launch show a clean, accessible role-selection screen.

Title:

**SafePath**

Subtitle:

**Smart Blind Stick Safety System**

Two large buttons/cards:

```text
[ I AM A BLIND STICK USER ]

[ I AM A CARETAKER ]
```

Store selected role locally so the user does not have to choose it every launch.

Provide a Settings/Profile option to switch role later.

---

# 3. BLIND STICK USER INTERFACE

The blind-user interface must prioritize simplicity, visibility, accessibility, and immediate emergency actions.

## Main sections

### A. ESP32 connection status

Display prominently:

```text
Stick: CONNECTED
```

or:

```text
Stick: DISCONNECTED
```

Connection means the Flutter app has successfully communicated with the ESP32, not merely that the phone is connected to Wi-Fi.

Use the ESP32:

```text
GET /app/heartbeat
```

as the application heartbeat.

The ESP32 firmware reports:

```text
SAFEPATH MOBILE APP CONNECTED SUCCESSFULLY
```

in Serial Monitor when the app heartbeat is received.

The app should send the heartbeat periodically.

---

## B. Live sensor dashboard

Show REAL data coming from:

```text
GET /sensors
```

Update the UI continuously.

Display:

### Ultrasonic

```text
LEFT       XX.X cm
MIDDLE     XX.X cm
RIGHT      XX.X cm
```

Use clear visual states:

```text
> 20 cm       Safe
< 20 cm       Danger
No echo       Sensor unavailable
```

Do not invent values.

### MPU6050

Display:

```text
Acceleration: X.XX G
Tilt:         XX.X°
Fall:         NORMAL / FALL DETECTED
```

Optionally expose advanced data under an expandable section:

```text
AX
AY
AZ
GX
GY
GZ
Temperature
```

### Overall status

Show:

```text
Stick Status:      ONLINE
MPU6050:           OK
Left Ultrasonic:   OK
Middle Ultrasonic: OK
Right Ultrasonic:  OK
SOS:               NORMAL
```

Use actual fields from `/sensors` and `/health`.

---

# 4. EMERGENCY CONTACT

The blind user must be able to add an emergency contact.

Screen:

```text
Emergency Contact

Name
Phone Number

[ Save Emergency Contact ]
```

Validate phone number.

Store the contact securely.

Also sync it to Firebase for the user's account/device.

Do not put sensitive contact information in an unauthenticated public database.

Allow:

```text
Edit
Delete
Test alert
```

The normal SOS flow must use the saved emergency contact.

---

# 5. SOS BEHAVIOR

SOS can be triggered by:

```text
A. MPU6050 fall detection
B. Physical SOS button
```

Firmware exposes:

```json
"sos_active": true
```

and:

```text
GET /sos-status
```

The app must continuously monitor the real SOS state.

### When SOS is detected:

The blind-user phone must:

1. Immediately detect the SOS.
2. Get the phone's current GPS coordinates.
3. Create an SOS event in Firebase.
4. Send location + SOS information to the configured emergency contact/caretaker using the implemented real notification mechanism.
5. Show a full-screen emergency status.
6. Keep showing the event as active until acknowledged/cleared.
7. Call:

```text
GET /clear-sos
```

only after the app has successfully processed the event.

Never clear SOS merely because `/sensors` was read.

---

# 6. SOS MESSAGE CONTENT

The generated alert should include:

```text
🚨 SAFEPATH SOS ALERT 🚨

An emergency has been detected by the SafePath Blind Stick.

Trigger:
FALL / SOS BUTTON

User:
<user name>

Time:
<timestamp>

Location:
<Google Maps link>

The SafePath stick is reporting an active emergency.
```

Use a real production mechanism.

For automatic remote notification, prefer:

```text
Firebase Cloud Functions + FCM
```

For SMS, use a real SMS provider/backend rather than pretending Flutter silently sends SMS.

The implementation must clearly document any external service credentials required.

---

# 7. CARETAKER INTERFACE

The caretaker gets a separate dashboard.

Main goal:

**Know where the blind user is, whether they are safe, and what the stick is reporting.**

## Caretaker dashboard

Top status bar:

```text
BLIND USER
● ONLINE / OFFLINE

STICK
● CONNECTED / DISCONNECTED

SOS
NORMAL / ACTIVE
```

---

# 8. LIVE MAP

The caretaker interface must contain a real interactive map.

Use:

```text
Google Maps Flutter
```

or another production map provider configured with a real API key.

Do not use a fake/static map.

Show:

```text
Blind User current location
```

The blind user's phone sends:

```text
latitude
longitude
timestamp
accuracy
speed
heading
```

to Firebase.

Caretaker subscribes to the real-time Firebase document/stream.

When location changes, update the marker without needing manual refresh.

Display:

```text
Last updated: X seconds ago
GPS accuracy: XX m
```

If GPS has become stale, clearly show:

```text
LOCATION STALE
```

rather than displaying the last location as live.

---

# 9. CARETAKER SENSOR PANEL

Show all important real telemetry.

### Ultrasonic

```text
LEFT       XX.X cm
MIDDLE     XX.X cm
RIGHT      XX.X cm
```

### MPU6050

```text
Acceleration   X.XX G
Tilt           XX.X°
Fall           NORMAL / DETECTED
```

### Stick

```text
Device ID
Wi-Fi state
App connection
Last sensor update
SOS state
Battery (only if actual hardware support exists)
```

Do not display a fake battery percentage if the ESP32 hardware does not measure battery voltage.

---

# 10. CARETAKER SOS SCREEN

When SOS becomes active:

```text
┌───────────────────────────────┐
│        🚨 SOS ACTIVE          │
│                               │
│ Trigger: FALL                 │
│ Time: 10:32:18                │
│                               │
│ LOCATION                      │
│ 12.xxxxx, 80.xxxxx            │
│                               │
│ [ OPEN LIVE MAP ]             │
│ [ CALL USER ]                 │
│ [ ACKNOWLEDGE ]               │
└───────────────────────────────┘
```

The application must make the SOS impossible to miss.

---

# 11. FIREBASE DATA MODEL

Use authenticated Firebase services.

Suggested Firestore structure:

```text
users/
  {{userId}}
    role: "blind_user" | "caretaker"
    name
    phone
    createdAt

devices/
  {{deviceId}}
    ownerUserId
    deviceStatus
    appConnected
    mpu6050Available
    sosActive
    updatedAt

devices/{{deviceId}}/telemetry/current
    leftDistanceCm
    middleDistanceCm
    rightDistanceCm
    ax
    ay
    az
    gx
    gy
    gz
    accelerationG
    tiltDeg
    fallDetected
    sosActive
    timestamp

devices/{{deviceId}}/location/current
    latitude
    longitude
    accuracy
    speed
    heading
    timestamp

devices/{{deviceId}}/emergencyContact/current
    name
    phone

devices/{{deviceId}}/sosEvents/{{eventId}}
    type
    timestamp
    latitude
    longitude
    mapsUrl
    acknowledged
    resolvedAt
```

Use Firebase Security Rules so one user cannot read another user's private data without authorization.

---

# 12. DEVICE PAIRING

Do not hard-code the caretaker relationship.

Use a real pairing mechanism.

Preferred:

```text
Blind User:
Device ID / Pairing Code
        ↓
Caretaker enters pairing code
        ↓
Firebase verifies pairing
        ↓
Caretaker gains permission to view that user's device
```

The ESP32 device ID is:

```text
ESP32-SAFEPATH-01
```

The device ID can be displayed in the blind-user settings.

Implement a secure way to associate the device with the blind-user Firebase account.

---

# 13. REAL ESP32 COMMUNICATION

The ESP32 creates a Wi-Fi access point:

```text
SSID:
SafePath_SmartStick

Password:
SafePath2026
```

The app must allow the user to connect to the stick's Wi-Fi.

ESP32 default IP from `WiFi.softAPIP()` will normally be used.

Do not assume an Internet connection through the ESP32.

The blind-user app should discover/use the ESP32 local IP and communicate using HTTP.

Endpoints:

```text
GET /
GET /sensors
GET /sos-status
GET /app/heartbeat
GET /health
GET /clear-sos
```

---

# 14. SENSOR JSON CONTRACT

The Flutter app must use the real JSON fields returned by the current firmware.

Example schema:

```json
{
  "device_id": "ESP32-SAFEPATH-01",
  "device_status": "connected",
  "left_distance_cm": 25.4,
  "middle_distance_cm": 18.7,
  "right_distance_cm": 42.8,
  "left_sensor_status": "ok",
  "middle_sensor_status": "ok",
  "right_sensor_status": "ok",
  "mpu6050_available": true,
  "ax": 0.12,
  "ay": -0.32,
  "az": 9.65,
  "gx": 0.03,
  "gy": -0.02,
  "gz": 0.10,
  "temperature": 29.2,
  "acceleration_g": 0.99,
  "tilt_deg": 4.5,
  "fall_detected": false,
  "sos_active": false,
  "sos_pressed": false,
  "wifi_connected": true,
  "app_connected": true,
  "connected_clients": 1,
  "uptime_ms": 123456,
  "free_heap": 200000,
  "wifi_rssi": -45
}
```

The actual values will be supplied by the hardware.

Do not insert sample values into production runtime code.

---

# 15. MOBILE APP POLLING / STREAMING STRATEGY

Use a clean service architecture.

Suggested Flutter structure:

```text
lib/
  main.dart

  core/
    constants/
    theme/
    routing/
    utils/

  models/
    sensor_data.dart
    location_data.dart
    emergency_contact.dart
    sos_event.dart
    device_status.dart

  services/
    esp32_service.dart
    firebase_service.dart
    location_service.dart
    notification_service.dart
    pairing_service.dart

  repositories/
    stick_repository.dart
    user_repository.dart
    caretaker_repository.dart

  features/
    role_selection/
    blind_user/
      dashboard/
      emergency_contact/
      device_connection/
      sos/
      settings/

    caretaker/
      dashboard/
      live_map/
      sensor_monitor/
      sos/
      pairing/

  widgets/
    status_card.dart
    sensor_card.dart
    connection_indicator.dart
    sos_banner.dart
```

Use state management such as:

```text
Riverpod
```

or another maintainable production architecture.

Keep hardware communication, Firebase, GPS, and UI separate.

---

# 16. ACCESSIBILITY

The blind-user interface should be optimized for accessibility.

Required:

- Large touch targets.
- High-contrast design.
- Large readable text.
- Screen-reader-friendly labels.
- Clear audio/visual status.
- Very prominent SOS controls.
- No complicated navigation.
- Avoid unnecessary animations.
- Use semantic Flutter widgets.

The blind-user should immediately understand:

```text
Stick connected?
Sensors working?
SOS active?
Emergency contact configured?
```

---

# 17. PHASED IMPLEMENTATION

## PHASE 1 — REAL ESP32 + BLIND USER APP

Build only the blind-user side first.

### Deliverables

1. Flutter Android project.
2. Role selection.
3. Blind-user dashboard.
4. ESP32 Wi-Fi connection handling.
5. Real HTTP communication.
6. `/app/heartbeat`.
7. `/health`.
8. `/sensors`.
9. Live ultrasonic values.
10. Live MPU6050 values.
11. Real fall state.
12. Real SOS state.
13. Emergency contact CRUD.
14. Device connection status.
15. Error handling for:
   - ESP32 unavailable
   - HTTP timeout
   - invalid JSON
   - Wi-Fi disconnected
   - sensor unavailable

### Phase 1 rule

**NO SIMULATION.**

The dashboard must remain empty/error-state when hardware is unavailable rather than showing fake values.

### Phase 1 acceptance test

With real ESP32:

```text
Phone connects to SafePath_SmartStick
        ↓
App calls /app/heartbeat
        ↓
Serial Monitor confirms app connected
        ↓
App reads /sensors
        ↓
Real ultrasonic distances appear
        ↓
Real MPU6050 values appear
        ↓
Press physical SOS button
        ↓
sos_active becomes true
        ↓
App displays SOS
```

---

# PHASE 2 — FIREBASE + CARETAKER + REAL GPS

Build the cloud and caretaker functionality.

### Deliverables

1. Firebase project integration.
2. Firebase Authentication.
3. Firestore database.
4. Security rules.
5. Device pairing.
6. Blind-user GPS permission.
7. Real background/foreground location handling appropriate for Android.
8. Upload current GPS location to Firebase.
9. Upload telemetry to Firebase.
10. Caretaker authentication.
11. Caretaker pairing.
12. Live map.
13. Real-time sensor dashboard.
14. Online/offline detection.
15. Last-update timestamps.

### Phase 2 acceptance test

Use two actual Android devices:

```text
Phone A = blind-user
Phone B = caretaker
```

Phone A:

```text
ESP32 connected
GPS enabled
Firebase connected
```

Phone B:

```text
Caretaker account
Paired with Phone A/device
```

When Phone A moves:

```text
Phone A GPS
   ↓
Firebase
   ↓
Phone B live map
```

The marker must move using actual location.

No simulated coordinates.

---

# PHASE 3 — REAL SOS + EMERGENCY NOTIFICATION + APK

Complete the production flow.

### Deliverables

1. Fall-triggered SOS.
2. Physical-button SOS.
3. SOS event recording.
4. GPS capture at SOS time.
5. Firebase SOS event.
6. Caretaker real-time SOS notification.
7. Emergency contact notification.
8. SOS acknowledgement.
9. SOS resolution.
10. `/clear-sos` integration.
11. Offline/retry handling.
12. App lifecycle handling.
13. Background notification handling.
14. Production Android permissions.
15. Release APK.

### End-to-end acceptance test

Test both:

### Test A — button

```text
Press physical SOS button
        ↓
ESP32 sets sos_active
        ↓
Phone detects SOS
        ↓
Phone gets GPS
        ↓
Firebase SOS event created
        ↓
Caretaker receives alert
        ↓
Caretaker sees current location
        ↓
Emergency contact receives notification
        ↓
SOS remains active
        ↓
Acknowledgement/clear flow
        ↓
ESP32 /clear-sos
```

### Test B — fall

```text
Real physical fall event
        ↓
MPU6050 detects fall
        ↓
ESP32 triggers SOS
        ↓
Same process as Test A
```

---

# 18. NO-SIMULATION REQUIREMENT

This is mandatory.

Do NOT create:

```text
fakeSensorData()
MockGPS()
DummyFirebaseService
SimulatedDevice
DemoTelemetry
FakeSOS
random sensor values
hard-coded location
```

Do NOT use fake coordinates as runtime data.

When hardware/cloud is unavailable, show a clear real error state.

---

# 19. ERROR STATES

Implement clear states for:

```text
ESP32 NOT FOUND
WIFI DISCONNECTED
APP HEARTBEAT LOST
SENSOR DATA TIMEOUT
MPU6050 UNAVAILABLE
ULTRASONIC SENSOR UNAVAILABLE
GPS PERMISSION DENIED
GPS UNAVAILABLE
FIREBASE OFFLINE
CARETAKER NOT PAIRED
SOS DELIVERY FAILED
```

Every failure should have an understandable user-facing message and retry mechanism.

---

# 20. SECURITY

Do not expose Firebase data publicly.

Implement:

- Firebase Authentication.
- Firestore Security Rules.
- Pairing authorization.
- Least-privilege device access.
- No private API credentials hard-coded into source control.
- Android permission handling.
- Secure storage for sensitive local settings where appropriate.

Do not commit:

```text
Firebase Admin credentials
service-account private keys
Twilio secrets
private API keys
```

Use environment/configuration mechanisms where appropriate.

---

# 21. GOOGLE MAPS

For caretaker map use a real provider.

Preferred:

```text
google_maps_flutter
```

Requirements:

- Actual Android Maps API key.
- Current location marker.
- Accuracy circle if supported.
- Last update timestamp.
- Tap marker for user/device information.
- Open external Google Maps navigation if desired.
- Graceful map error if API key is missing.

At the end, explain exactly where the Android Maps API key is configured.

---

# 22. ANDROID PERMISSIONS

Configure required permissions for actual functionality.

At minimum evaluate:

```text
INTERNET
ACCESS_FINE_LOCATION
ACCESS_COARSE_LOCATION
POST_NOTIFICATIONS
```

For background location, only request it if the implemented SOS/live-location architecture truly requires it, and configure the correct Android behavior.

Do not request unnecessary permissions.

---

# 23. APP UI QUALITY

Make the interface professional.

Blind-user theme:

```text
Simple
Large
High contrast
Accessibility focused
Minimal navigation
Emergency-first
```

Caretaker theme:

```text
Professional monitoring dashboard
Map focused
Live status cards
Sensor telemetry
SOS alerts
Connection state
```

Do not make both interfaces look identical.

---

# 24. REQUIRED DEVELOPMENT BEHAVIOR

Work phase by phase.

At the end of each phase:

1. Run `flutter analyze`.
2. Run tests where meaningful.
3. Build/run on a real Android device.
4. Fix compilation errors.
5. Fix runtime errors.
6. Verify real ESP32 communication where applicable.
7. Clearly report what works.
8. Clearly report what remains.

Do not move to the next phase with known blocking build/runtime errors.

---

# 25. FINAL DELIVERABLE

At the end of Phase 3, provide:

## A. Source

Explain:

```text
Flutter project location
Important files
Firebase configuration
Android configuration
ESP32 endpoint configuration
```

## B. APK BUILD

Give exact commands, for example:

```bash
flutter clean
flutter pub get
flutter analyze
flutter build apk --release
```

Then tell me the exact APK path produced.

Do not invent the path if the build produces a different one. Report the actual generated path.

## C. APK DOWNLOAD / INSTALL STEPS

Tell me exactly:

1. Where the APK is generated.
2. How to copy it to an Android phone.
3. How to install it.
4. Which Android permissions must be granted.
5. How to connect the phone to:
   `SafePath_SmartStick`
6. How to open the app.
7. How to configure the blind-user account.
8. How to add the emergency contact.
9. How to pair a caretaker.
10. How to test live GPS.
11. How to test ultrasonic data.
12. How to test MPU6050.
13. How to test the physical SOS button.
14. How to test the complete SOS notification flow.

## D. PRODUCTION SETUP CHECKLIST

Provide a final checklist for:

```text
ESP32 flashed
ESP32 Wi-Fi working
Phone connected
App heartbeat working
Ultrasonic working
MPU6050 working
SOS button working
GPS permission granted
Firebase connected
Caretaker paired
Map working
Emergency contact configured
SOS tested
Release APK built
```

---

# 26. IMPORTANT CURRENT ESP32 FIRMWARE CONTRACT

The following firmware is the actual hardware firmware context. Use this code/API contract; do not redesign the hardware pins or invent different endpoint names unless absolutely required and clearly documented.

```cpp
/* 
 * ============================================================
 * SAFEPATH SMART BLIND STICK
 * ESP32 PRODUCTION HARDWARE FIRMWARE - UPDATED
 * ============================================================
 *
 * Updates:
 * 1. Improved MPU6050 fall detection:
 *    - 50 Hz MPU sampling
 *    - free-fall -> impact sequence
 *    - high-impact fallback
 *    - post-impact orientation/gyro confirmation
 *    - cooldown/debounce
 *
 * 2. Explicit mobile connection status:
 *    - Wi-Fi station connection
 *    - app heartbeat (/app/heartbeat)
 *    - Serial Monitor reports both states
 *
 * 3. Persistent SOS:
 *    - fall OR button triggers SOS
 *    - continuous local SOS beep
 *    - /sensors DOES NOT clear SOS
 *    - mobile app must acknowledge with /clear-sos
 *
 * 4. Directional obstacle beep patterns:
 *    - MIDDLE: equal beep + equal beep
 *    - LEFT:   long beep + short beep
 *    - RIGHT:  short beep + long beep
 *    - pattern repeats continuously
 *
 * 5. LED is driven from the same beep state as the buzzer,
 *    so buzzer and LED are synchronized.
 *
 * IMPORTANT:
 * HC-SR04 ECHO is normally 5V. ESP32 GPIO is 3.3V logic.
 * USE A VOLTAGE DIVIDER ON EACH ECHO LINE.
 *
 * IMPORTANT APP ARCHITECTURE:
 * The ESP32 does not have GPS. The mobile app must:
 *   - poll /sensors or /sos-status
 *   - detect sos_active == true
 *   - get the phone GPS location
 *   - send the SOS + location to the emergency contact
 *   - call /clear-sos after the app has processed the event
 */

#include <WiFi.h>
#include <WebServer.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <ArduinoJson.h>
#include <math.h>

// ============================================================
// WIFI CONFIGURATION
// ============================================================

const char* AP_SSID = "SafePath_SmartStick";
const char* AP_PASSWORD = "SafePath2026";

WebServer server(80);

// ============================================================
// FIXED HARDWARE PIN MAPPING
// ============================================================

#define LEFT_TRIG       5
#define LEFT_ECHO       18
#define MIDDLE_TRIG     19
#define MIDDLE_ECHO     21
#define RIGHT_TRIG      22
#define RIGHT_ECHO      23
#define MPU_SDA         25
#define MPU_SCL         26
#define SOS_BUTTON      27
#define BUZZER          32
#define LED_PIN         33

// ============================================================
// SYSTEM SETTINGS
// ============================================================

#define DANGER_THRESHOLD_CM         20.0f
#define ULTRASONIC_TIMEOUT_US       30000UL

#define ULTRASONIC_UPDATE_MS        100UL
#define MPU_UPDATE_MS               20UL
#define FALL_COOLDOWN_MS            8000UL

#define APP_HEARTBEAT_TIMEOUT_MS    6000UL

#define FREEFALL_THRESHOLD_G        0.55f
#define IMPACT_THRESHOLD_G          2.20f
#define HARD_IMPACT_THRESHOLD_G     3.00f
#define POST_FALL_TILT_DEG          45.0f
#define FALL_SEQUENCE_WINDOW_MS     900UL

// ============================================================
// MPU6050
// ============================================================

Adafruit_MPU6050 mpu;
bool mpuFound = false;

// ============================================================
// SENSOR DATA
// ============================================================

float leftDistance = -1.0f;
float middleDistance = -1.0f;
float rightDistance = -1.0f;

float ax = 0.0f;
float ay = 0.0f;
float az = 0.0f;

float gx = 0.0f;
float gy = 0.0f;
float gz = 0.0f;

float temperature = 0.0f;
float totalAccelerationG = 1.0f;
float previousAccelG = 1.0f;

// Slowly adapting reference orientation. This avoids assuming that
// the MPU6050 is mounted perfectly vertical on the stick.
float baselineAx = 0.0f;
float baselineAy = 0.0f;
float baselineAz = 9.80665f;
bool orientationBaselineValid = false;

// ============================================================
// SAFETY / EVENT STATE
// ============================================================

volatile bool sosActive = false;
volatile bool fallDetected = false;
bool sosButtonEvent = false;

unsigned long lastFallTime = 0;
unsigned long lastSensorUpdate = 0;
unsigned long lastMPUUpdate = 0;
unsigned long lastWiFiStatus = 0;
unsigned long lastAppHeartbeat = 0;

bool lastMobileWiFiConnected = false;
bool lastAppConnected = false;

// Fall sequence state
bool freeFallDetected = false;
unsigned long freeFallStart = 0;
bool impactDetectedAfterFreeFall = false;
unsigned long impactTime = 0;

// ============================================================
// BUZZER / LED PATTERN STATE
// ============================================================

enum BeepPattern {
    PATTERN_NONE,
    PATTERN_MIDDLE,
    PATTERN_LEFT,
    PATTERN_RIGHT,
    PATTERN_SOS
};

BeepPattern activePattern = PATTERN_NONE;

bool outputOn = false;
unsigned long patternTimer = 0;
uint8_t patternStep = 0;

// Middle: equal + equal
const unsigned long MIDDLE_ON_1  = 180;
const unsigned long MIDDLE_OFF_1 = 120;
const unsigned long MIDDLE_ON_2  = 180;
const unsigned long MIDDLE_OFF_2 = 400;

// Left: long + short
const unsigned long LEFT_ON_1    = 320;
const unsigned long LEFT_OFF_1   = 120;
const unsigned long LEFT_ON_2    = 120;
const unsigned long LEFT_OFF_2   = 400;

// Right: short + long
const unsigned long RIGHT_ON_1   = 120;
const unsigned long RIGHT_OFF_1  = 120;
const unsigned long RIGHT_ON_2   = 320;
const unsigned long RIGHT_OFF_2  = 400;

// ============================================================
// HELPER: BUZZER + LED TOGETHER
// ============================================================

void setAlarmOutput(bool state)
{
    outputOn = state;

    // Both outputs are changed together, so their logical timing
    // remains synchronized.
    digitalWrite(BUZZER, state ? HIGH : LOW);
    digitalWrite(LED_PIN, state ? HIGH : LOW);
}

// ============================================================
// ULTRASONIC SENSOR
// ============================================================

float readDistance(int trigPin, int echoPin)
{
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);

    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);

    unsigned long duration =
        pulseIn(echoPin, HIGH, ULTRASONIC_TIMEOUT_US);

    if (duration == 0) {
        return -1.0f;
    }

    float distance = (duration * 0.0343f) / 2.0f;

    if (distance < 2.0f || distance > 450.0f) {
        return -1.0f;
    }

    return distance;
}

void updateUltrasonicSensors()
{
    // Sequential reads reduce ultrasonic cross-talk.
    leftDistance = readDistance(LEFT_TRIG, LEFT_ECHO);
    delay(5);

    middleDistance = readDistance(MIDDLE_TRIG, MIDDLE_ECHO);
    delay(5);

    rightDistance = readDistance(RIGHT_TRIG, RIGHT_ECHO);
}

// ============================================================
// MPU6050 FALL DETECTION
// ============================================================

float calculateTiltFromGravity()
{
    float magnitude = sqrtf(ax * ax + ay * ay + az * az);

    if (magnitude < 0.5f) {
        return 0.0f;
    }

    float cosAngle = fabsf(az) / magnitude;

    if (cosAngle > 1.0f) cosAngle = 1.0f;

    return acosf(cosAngle) * 180.0f / PI;
}

float calculateOrientationChangeDeg()
{
    if (!orientationBaselineValid) {
        return 0.0f;
    }

    float currentMag = sqrtf(ax * ax + ay * ay + az * az);
    float baselineMag =
        sqrtf(baselineAx * baselineAx +
              baselineAy * baselineAy +
              baselineAz * baselineAz);

    if (currentMag < 0.5f || baselineMag < 0.5f) {
        return 0.0f;
    }

    float dot =
        (ax * baselineAx +
         ay * baselineAy +
         az * baselineAz) /
        (currentMag * baselineMag);

    if (dot > 1.0f) dot = 1.0f;
    if (dot < -1.0f) dot = -1.0f;

    return acosf(dot) * 180.0f / PI;
}

void updateOrientationBaseline()
{
    if (!mpuFound) {
        return;
    }

    float gyroMagnitude =
        sqrtf(gx * gx + gy * gy + gz * gz);

    // Learn reference orientation only while relatively stable.
    if (totalAccelerationG > 0.85f &&
        totalAccelerationG < 1.15f &&
        gyroMagnitude < 0.70f) {

        if (!orientationBaselineValid) {
            baselineAx = ax;
            baselineAy = ay;
            baselineAz = az;
            orientationBaselineValid = true;
        }
        else {
            const float alpha = 0.01f;
            baselineAx += alpha * (ax - baselineAx);
            baselineAy += alpha * (ay - baselineAy);
            baselineAz += alpha * (az - baselineAz);
        }
    }
}

void triggerSOS(const char* reason)
{
    if (!sosActive) {
        Serial.println();
        Serial.println("==========================================");
        Serial.print("!!! SOS TRIGGERED: ");
        Serial.println(reason);
        Serial.println("==========================================");
    }

    sosActive = true;

    if (strcmp(reason, "FALL") == 0) {
        fallDetected = true;
        lastFallTime = millis();
    }

    // SOS has priority over obstacle warnings.
    activePattern = PATTERN_SOS;
    patternStep = 0;
    patternTimer = millis();
    setAlarmOutput(true);
}

void updateMPU6050()
{
    if (!mpuFound) {
        return;
    }

    sensors_event_t acceleration;
    sensors_event_t gyro;
    sensors_event_t temp;

    mpu.getEvent(&acceleration, &gyro, &temp);

    ax = acceleration.acceleration.x;
    ay = acceleration.acceleration.y;
    az = acceleration.acceleration.z;

    gx = gyro.gyro.x;
    gy = gyro.gyro.y;
    gz = gyro.gyro.z;

    temperature = temp.temperature;

    float totalAcceleration =
        sqrtf(ax * ax + ay * ay + az * az);

    totalAccelerationG = totalAcceleration / 9.80665f;

    unsigned long now = millis();

    if (now - lastFallTime < FALL_COOLDOWN_MS) {
        updateOrientationBaseline();
        previousAccelG = totalAccelerationG;
        return;
    }

    // Stage 1: free-fall.
    if (!freeFallDetected &&
        totalAccelerationG <= FREEFALL_THRESHOLD_G) {

        freeFallDetected = true;
        freeFallStart = now;

        Serial.println("MPU6050: possible free-fall detected");
    }

    // Stage 2: impact after free-fall.
    if (freeFallDetected) {

        if (now - freeFallStart > FALL_SEQUENCE_WINDOW_MS) {
            freeFallDetected = false;
        }
        else if (totalAccelerationG >= IMPACT_THRESHOLD_G) {

            impactDetectedAfterFreeFall = true;
            impactTime = now;
            freeFallDetected = false;

            float tilt = calculateTiltFromGravity();

            Serial.print("MPU6050: impact after free-fall, G=");
            Serial.print(totalAccelerationG, 2);
            Serial.print(" tilt=");
            Serial.print(tilt, 1);
            Serial.print(" deg, orientation change=");
            Serial.print(calculateOrientationChangeDeg(), 1);
            Serial.println(" deg");

            // Free-fall + impact is the primary fall signature.
            triggerSOS("FALL");
        }
    }

    // Stage 3: hard-impact fallback.
    if (!sosActive &&
        totalAccelerationG >= HARD_IMPACT_THRESHOLD_G) {

        float tilt = calculateTiltFromGravity();
        float orientationChange = calculateOrientationChangeDeg();
        float gyroMagnitude =
            sqrtf(gx * gx + gy * gy + gz * gz);

        Serial.print("MPU6050: hard impact, G=");
        Serial.print(totalAccelerationG, 2);
        Serial.print(" tilt=");
        Serial.print(tilt, 1);
        Serial.print(" deg, orientation change=");
        Serial.print(orientationChange, 1);
        Serial.print(" deg, gyro=");
        Serial.print(gyroMagnitude, 2);
        Serial.println(" rad/s");

        // Hard impact alone can be caused by hitting an obstacle.
        // Require orientation change OR strong rotation to reduce
        // false alarms.
        if (orientationChange >= POST_FALL_TILT_DEG ||
            gyroMagnitude >= 3.0f) {
            triggerSOS("FALL");
        }
    }

    updateOrientationBaseline();
    previousAccelG = totalAccelerationG;

    if (fallDetected &&
        now - lastFallTime > FALL_COOLDOWN_MS) {
        fallDetected = false;
    }
}

// ============================================================
// OBSTACLE DIRECTION
// ============================================================

bool validDanger(float distance)
{
    return distance > 0.0f &&
           distance < DANGER_THRESHOLD_CM;
}

BeepPattern determineObstaclePattern()
{
    bool leftDanger = validDanger(leftDistance);
    bool middleDanger = validDanger(middleDistance);
    bool rightDanger = validDanger(rightDistance);

    // Middle has highest priority because it is directly ahead.
    if (middleDanger) {
        return PATTERN_MIDDLE;
    }

    if (!leftDanger && !rightDanger) {
        return PATTERN_NONE;
    }

    if (leftDanger && !rightDanger) {
        return PATTERN_LEFT;
    }

    if (rightDanger && !leftDanger) {
        return PATTERN_RIGHT;
    }

    // Both side sensors detect something: warn for the closer side.
    if (leftDistance <= rightDistance) {
        return PATTERN_LEFT;
    }

    return PATTERN_RIGHT;
}

// ============================================================
// BEEP PATTERN ENGINE
// ============================================================

void startPattern(BeepPattern pattern)
{
    if (activePattern != pattern) {
        activePattern = pattern;
        patternStep = 0;
        patternTimer = millis();

        if (pattern == PATTERN_SOS) {
            setAlarmOutput(true);
        }
        else if (pattern == PATTERN_NONE) {
            setAlarmOutput(false);
        }
        else {
            setAlarmOutput(true);
        }
    }
}

unsigned long currentPatternDuration(BeepPattern pattern,
                                     uint8_t step)
{
    if (pattern == PATTERN_MIDDLE) {
        if (step == 0) return MIDDLE_ON_1;
        if (step == 1) return MIDDLE_OFF_1;
        if (step == 2) return MIDDLE_ON_2;
        return MIDDLE_OFF_2;
    }

    if (pattern == PATTERN_LEFT) {
        if (step == 0) return LEFT_ON_1;
        if (step == 1) return LEFT_OFF_1;
        if (step == 2) return LEFT_ON_2;
        return LEFT_OFF_2;
    }

    if (pattern == PATTERN_RIGHT) {
        if (step == 0) return RIGHT_ON_1;
        if (step == 1) return RIGHT_OFF_1;
        if (step == 2) return RIGHT_ON_2;
        return RIGHT_OFF_2;
    }

    return 0;
}

bool patternStepOutput(uint8_t step)
{
    return (step == 0 || step == 2);
}

void updateBuzzerAndLED()
{
    // SOS always has priority and is continuous.
    if (sosActive) {
        if (!outputOn) {
            setAlarmOutput(true);
        }
        activePattern = PATTERN_SOS;
        return;
    }

    BeepPattern desiredPattern = determineObstaclePattern();

    if (desiredPattern != activePattern) {
        startPattern(desiredPattern);
    }

    if (activePattern == PATTERN_NONE) {
        setAlarmOutput(false);
        return;
    }

    unsigned long now = millis();

    if (now - patternTimer >=
        currentPatternDuration(activePattern, patternStep)) {

        patternTimer = now;
        patternStep++;

        if (patternStep >= 4) {
            patternStep = 0;
        }

        setAlarmOutput(patternStepOutput(patternStep));
    }
}

// ============================================================
// SOS BUTTON
// ============================================================

void checkSOSButton()
{
    static bool lastRawState = HIGH;
    static bool stableState = HIGH;
    static unsigned long lastDebounce = 0;

    bool rawState = digitalRead(SOS_BUTTON);
    unsigned long now = millis();

    if (rawState != lastRawState) {
        lastDebounce = now;
        lastRawState = rawState;
    }

    if ((now - lastDebounce) > 40 &&
        rawState != stableState) {

        stableState = rawState;

        if (stableState == LOW) {
            sosButtonEvent = true;

            Serial.println();
            Serial.println("================================");
            Serial.println("       SOS BUTTON PRESSED");
            Serial.println("================================");

            triggerSOS("BUTTON");
        }
    }
}

// ============================================================
// MOBILE APP CONNECTION
// ============================================================

bool isMobileWiFiConnected()
{
    return WiFi.softAPgetStationNum() > 0;
}

bool isMobileAppConnected()
{
    return isMobileWiFiConnected() &&
           (millis() - lastAppHeartbeat <=
            APP_HEARTBEAT_TIMEOUT_MS);
}

void updateMobileConnectionStatus()
{
    bool wifiConnected = isMobileWiFiConnected();
    bool appConnected = isMobileAppConnected();

    if (wifiConnected != lastMobileWiFiConnected) {
        if (wifiConnected) {
            Serial.println();
            Serial.println(">>> MOBILE PHONE CONNECTED TO ESP32 Wi-Fi <<<");
            Serial.print(">>> Phone can access: http://");
            Serial.print(WiFi.softAPIP());
            Serial.println(" <<<");
        }
        else {
            Serial.println();
            Serial.println(">>> MOBILE PHONE DISCONNECTED FROM ESP32 Wi-Fi <<<");
        }

        lastMobileWiFiConnected = wifiConnected;
    }

    if (appConnected != lastAppConnected) {
        if (appConnected) {
            Serial.println();
            Serial.println(">>> SAFEPATH MOBILE APP CONNECTED SUCCESSFULLY <<<");
        }
        else if (wifiConnected) {
            Serial.println();
            Serial.println(">>> Wi-Fi connected, but app heartbeat is missing <<<");
        }
        else {
            Serial.println();
            Serial.println(">>> SAFEPATH MOBILE APP DISCONNECTED <<<");
        }

        lastAppConnected = appConnected;
    }
}

// ============================================================
// JSON SENSOR API
// ============================================================

void addSensorData(StaticJsonDocument<1536>& doc)
{
    doc["device_id"] = "ESP32-SAFEPATH-01";
    doc["device_status"] = "connected";

    if (leftDistance >= 0)
        doc["left_distance_cm"] = leftDistance;
    else
        doc["left_distance_cm"] = nullptr;

    if (middleDistance >= 0)
        doc["middle_distance_cm"] = middleDistance;
    else
        doc["middle_distance_cm"] = nullptr;

    if (rightDistance >= 0)
        doc["right_distance_cm"] = rightDistance;
    else
        doc["right_distance_cm"] = nullptr;

    doc["left_sensor_status"] =
        leftDistance >= 0 ? "ok" : "no_echo";

    doc["middle_sensor_status"] =
        middleDistance >= 0 ? "ok" : "no_echo";

    doc["right_sensor_status"] =
        rightDistance >= 0 ? "ok" : "no_echo";

    doc["mpu6050_available"] = mpuFound;

    if (mpuFound) {
        doc["ax"] = ax;
        doc["ay"] = ay;
        doc["az"] = az;
        doc["gx"] = gx;
        doc["gy"] = gy;
        doc["gz"] = gz;
        doc["temperature"] = temperature;
        doc["acceleration_g"] = totalAccelerationG;
        doc["tilt_deg"] = calculateTiltFromGravity();
    }

    // Persistent safety event.
    doc["fall_detected"] = fallDetected;
    doc["sos_active"] = sosActive;
    doc["sos_pressed"] = sosButtonEvent;

    // Connection state.
    doc["wifi_connected"] = isMobileWiFiConnected();
    doc["app_connected"] = isMobileAppConnected();
    doc["connected_clients"] = WiFi.softAPgetStationNum();

    doc["uptime_ms"] = millis();
    doc["free_heap"] = ESP.getFreeHeap();
    doc["wifi_rssi"] = WiFi.RSSI();
}

void handleSensors()
{
    StaticJsonDocument<1536> doc;
    addSensorData(doc);

    String response;
    serializeJson(doc, response);

    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", response);

    // DO NOT clear SOS here. The app may poll this endpoint repeatedly.
}

// ============================================================
// SOS STATUS API
// ============================================================

void handleSOSStatus()
{
    StaticJsonDocument<512> doc;

    doc["sos_active"] = sosActive;
    doc["fall_detected"] = fallDetected;
    doc["button_pressed"] = sosButtonEvent;
    doc["app_connected"] = isMobileAppConnected();

    String response;
    serializeJson(doc, response);

    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", response);
}

// ============================================================
// APP HEARTBEAT API
// ============================================================

void handleAppHeartbeat()
{
    lastAppHeartbeat = millis();

    Serial.println("APP HEARTBEAT RECEIVED - MOBILE APP CONNECTED");

    StaticJsonDocument<512> doc;

    doc["status"] = "app_connected";
    doc["device_id"] = "ESP32-SAFEPATH-01";
    doc["sos_active"] = sosActive;
    doc["ip"] = WiFi.softAPIP().toString();

    String response;
    serializeJson(doc, response);

    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", response);
}

// ============================================================
// CLEAR SOS
// ============================================================

void handleClearSOS()
{
    sosActive = false;
    fallDetected = false;
    sosButtonEvent = false;

    freeFallDetected = false;
    impactDetectedAfterFreeFall = false;

    activePattern = PATTERN_NONE;
    patternStep = 0;
    setAlarmOutput(false);

    Serial.println();
    Serial.println("SOS CLEARED BY MOBILE APP");

    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(
        200,
        "application/json",
        "{\"status\":\"cleared\",\"sos_active\":false}"
    );
}

// ============================================================
// ROOT API
// ============================================================

void handleRoot()
{
    String message;

    message += "SafePath Smart Blind Stick ESP32\n";
    message += "Status: ONLINE\n";
    message += "Device: ESP32-SAFEPATH-01\n";
    message += "Endpoints:\n";
    message += "  /sensors\n";
    message += "  /sos-status\n";
    message += "  /app/heartbeat\n";
    message += "  /health\n";
    message += "  /clear-sos\n";

    server.send(200, "text/plain", message);
}

// ============================================================
// HEALTH API
// ============================================================

void handleHealth()
{
    StaticJsonDocument<768> doc;

    doc["status"] = "ok";
    doc["device_id"] = "ESP32-SAFEPATH-01";
    doc["uptime_ms"] = millis();

    doc["mpu6050"] =
        mpuFound ? "ok" : "unavailable";

    doc["left_ultrasonic"] =
        leftDistance >= 0 ? "ok" : "no_echo";

    doc["middle_ultrasonic"] =
        middleDistance >= 0 ? "ok" : "no_echo";

    doc["right_ultrasonic"] =
        rightDistance >= 0 ? "ok" : "no_echo";

    doc["mobile_wifi_connected"] =
        isMobileWiFiConnected();

    doc["mobile_app_connected"] =
        isMobileAppConnected();

    doc["sos_active"] = sosActive;

    String response;
    serializeJson(doc, response);

    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", response);
}

// ============================================================
// SETUP
// ============================================================

void setup()
{
    Serial.begin(115200);
    delay(1000);

    Serial.println();
    Serial.println("==========================================");
    Serial.println("       SAFEPATH SMART BLIND STICK");
    Serial.println("       ESP32 HARDWARE FIRMWARE");
    Serial.println("==========================================");

    pinMode(LEFT_TRIG, OUTPUT);
    pinMode(LEFT_ECHO, INPUT);
    pinMode(MIDDLE_TRIG, OUTPUT);
    pinMode(MIDDLE_ECHO, INPUT);
    pinMode(RIGHT_TRIG, OUTPUT);
    pinMode(RIGHT_ECHO, INPUT);

    digitalWrite(LEFT_TRIG, LOW);
    digitalWrite(MIDDLE_TRIG, LOW);
    digitalWrite(RIGHT_TRIG, LOW);

    pinMode(SOS_BUTTON, INPUT_PULLUP);

    pinMode(BUZZER, OUTPUT);
    digitalWrite(BUZZER, LOW);

    pinMode(LED_PIN, OUTPUT);
    digitalWrite(LED_PIN, LOW);

    // --------------------------------------------------------
    // MPU6050
    // --------------------------------------------------------

    Serial.println();
    Serial.println("Initializing MPU6050...");

    Wire.begin(MPU_SDA, MPU_SCL);
    Wire.setClock(400000);

    if (!mpu.begin()) {
        Serial.println("ERROR: MPU6050 NOT FOUND");
        mpuFound = false;
    }
    else {
        Serial.println("MPU6050 FOUND SUCCESSFULLY");
        mpuFound = true;

        mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
        mpu.setGyroRange(MPU6050_RANGE_500_DEG);
        mpu.setFilterBandwidth(MPU6050_BAND_44_HZ);

        Serial.println("MPU6050 CONFIGURED:");
        Serial.println("  Accelerometer: +/-8G");
        Serial.println("  Gyroscope:     +/-500 deg/s");
        Serial.println("  Filter:        44 Hz");
        Serial.println("  Sampling:      50 Hz");
    }

    // --------------------------------------------------------
    // Wi-Fi Access Point
    // --------------------------------------------------------

    Serial.println();
    Serial.println("Starting SafePath Wi-Fi...");

    WiFi.mode(WIFI_AP);

    bool apStarted =
        WiFi.softAP(AP_SSID, AP_PASSWORD);

    if (apStarted) {
        Serial.println("Wi-Fi AP started successfully.");
        Serial.print("SSID: ");
        Serial.println(AP_SSID);

        Serial.print("IP Address: ");
        Serial.println(WiFi.softAPIP());

        Serial.println();
        Serial.println("Connect the user's mobile to this Wi-Fi.");
        Serial.println("Then the app must call:");
        Serial.println("GET /app/heartbeat");
    }
    else {
        Serial.println("ERROR: Wi-Fi AP failed.");
    }

    // --------------------------------------------------------
    // HTTP routes
    // --------------------------------------------------------

    server.on("/", HTTP_GET, handleRoot);
    server.on("/sensors", HTTP_GET, handleSensors);
    server.on("/sos-status", HTTP_GET, handleSOSStatus);
    server.on("/app/heartbeat", HTTP_GET, handleAppHeartbeat);
    server.on("/health", HTTP_GET, handleHealth);
    server.on("/clear-sos", HTTP_GET, handleClearSOS);

    server.begin();

    Serial.println();
    Serial.println("HTTP SERVER STARTED");
    Serial.println("GET /sensors");
    Serial.println("GET /sos-status");
    Serial.println("GET /app/heartbeat");
    Serial.println("GET /health");
    Serial.println("GET /clear-sos");

    // --------------------------------------------------------
    // Startup synchronization test
    // --------------------------------------------------------

    Serial.println();
    Serial.println("Running buzzer + LED synchronization test...");

    setAlarmOutput(true);
    delay(300);
    setAlarmOutput(false);
    delay(300);

    Serial.println("Buzzer + LED test complete.");

    Serial.println();
    Serial.println("==========================================");
    Serial.println("            SYSTEM READY");
    Serial.println("==========================================");

    Serial.println("LEFT   : TRIG GPIO 5  / ECHO GPIO 18");
    Serial.println("MIDDLE : TRIG GPIO 19 / ECHO GPIO 21");
    Serial.println("RIGHT  : TRIG GPIO 22 / ECHO GPIO 23");
    Serial.println("MPU6050: SDA GPIO 25 / SCL GPIO 26");
    Serial.println("SOS    : GPIO 27");
    Serial.println("BUZZER : GPIO 32");
    Serial.println("LED    : GPIO 33");
    Serial.println();
}

// ============================================================
// MAIN LOOP
// ============================================================

void loop()
{
    unsigned long now = millis();

    server.handleClient();

    checkSOSButton();

    // MPU: 50 Hz
    if (now - lastMPUUpdate >= MPU_UPDATE_MS) {
        lastMPUUpdate = now;
        updateMPU6050();
    }

    // Ultrasonic: 10 Hz
    if (now - lastSensorUpdate >= ULTRASONIC_UPDATE_MS) {
        lastSensorUpdate = now;
        updateUltrasonicSensors();
    }

    // Buzzer + LED: continuously updated
    updateBuzzerAndLED();

    // Connection status
    if (now - lastWiFiStatus >= 1000) {
        lastWiFiStatus = now;
        updateMobileConnectionStatus();
    }

    delay(1);
}

```

---

# 27. FINAL RULE

Build this as a **real end-to-end project**, not a UI prototype.

Do not stop at screen creation.

The final result must have:

```text
REAL ESP32
      +
REAL SENSOR DATA
      +
REAL MPU6050 FALL DETECTION
      +
REAL SOS BUTTON
      +
REAL PHONE GPS
      +
REAL FIREBASE
      +
REAL CARETAKER MAP
      +
REAL EMERGENCY ALERT FLOW
      +
REAL RELEASE APK
```

At the end, give a concise implementation report with:

```text
Phase 1: COMPLETE / BLOCKED
Phase 2: COMPLETE / BLOCKED
Phase 3: COMPLETE / BLOCKED

APK:
<actual path>

Setup:
<exact steps>

Known limitations:
<only real limitations>
```
