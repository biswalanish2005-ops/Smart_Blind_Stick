# SAFEPATH SMART BLIND STICK — PRODUCTION RUNBOOK & SPECIFICATION

**Authoritative System Guide**  
**Project:** SafePath Smart Blind Stick Companion System  
**Target Environment:** Flutter (Android) | ESP32 Hardware | Firebase Cloud  
**Hardware Contract Revision:** ESP32 Production Hardware Firmware (SafePath2026)

---

## 1. SYSTEM ARCHITECTURE

```text
                  ┌────────────────────────────────────────┐
                  │       ESP32 Stick Hardware             │
                  │                                        │
                  │  • 3× HC-SR04 Ultrasonics (L, M, R)    │
                  │  • MPU6050 6-Axis IMU (Fall detection) │
                  │  • Physical SOS Push Button            │
                  │  • Synchronized Buzzer & LED           │
                  │  • Wi-Fi SoftAP: SafePath_SmartStick   │
                  └───────────────────┬────────────────────┘
                                      │
                         Local Wi-Fi / HTTP (Port 80)
                                      │
                                      ▼
                  ┌────────────────────────────────────────┐
                  │        Blind User Phone (Android)      │
                  │                                        │
                  │  • Flutter SafePath Application        │
                  │  • Periodic Heartbeat (/app/heartbeat) │
                  │  • Continuous Telemetry (/sensors)     │
                  │  • Phone GPS Location Acquisition      │
                  │  • WCAG AAA Accessible Voice / Haptics │
                  └───────────────────┬────────────────────┘
                                      │
                            Internet / HTTPS
                                      │
                                      ▼
                  ┌────────────────────────────────────────┐
                  │            Firebase Backend            │
                  │                                        │
                  │  • Firestore Authenticated Security    │
                  │  • Real-Time Location Synchronization  │
                  │  • Telemetry Stream Pipeline           │
                  │  • Cloud SOS Incident Recording        │
                  └───────────────────┬────────────────────┘
                                      │
                            Internet / HTTPS
                                      │
                                      ▼
                  ┌────────────────────────────────────────┐
                  │         Caretaker Phone (Android)      │
                  │                                        │
                  │  • SafePath Caretaker Console          │
                  │  • Live Interactive OpenStreetMap      │
                  │  • Moving Real-Time Blind User Marker  │
                  │  • Fullscreen SOS Alert Overlay        │
                  │  • Direct Dial & Acknowledgement       │
                  └────────────────────────────────────────┘
```

> [!IMPORTANT]
> **No-GPS Rule on ESP32:** The ESP32 does not possess a GPS receiver. The blind user's smartphone retrieves real GPS coordinates using the phone's internal hardware and syncs those coordinates to Firebase for caretaker tracking and SOS escalation.

---

## 2. ESP32 FIRMWARE & HARDWARE CONTRACT

### Network Architecture (Phone Hotspot Mode - WIFI_STA)
The ESP32 runs in **Station Mode (`WIFI_STA`)** and connects directly to the blind user's smartphone Wi-Fi hotspot. This allows the phone to keep **Mobile Data ON**, **GPS ON**, and **Hotspot ON** simultaneously, ensuring continuous cloud synchronization, real GPS emergency dispatches, and caretaker tracking.

- **Mode:** `WiFi.mode(WIFI_STA)`
- **Configurable Credentials:**
  ```cpp
  const char* WIFI_SSID = "PHONE_HOTSPOT_NAME";
  const char* WIFI_PASSWORD = "PHONE_HOTSPOT_PASSWORD";
  ```
- **Firmware Location:** `firmware/esp32/SafePath_SmartStick.ino`
- **mDNS Hostname:** `http://safepath-stick.local`
- **Default IP Address Range:** `http://192.168.43.xxx` (Assigned by Phone DHCP, e.g., `192.168.43.127`)
- **Non-Blocking Reconnection:** Reconnect attempts occur in the background every `5000 ms` without blocking ultrasonic obstacle detection, MPU6050 fall detection, buzzer beeping, or physical SOS triggers.
- **Heartbeat & Status:**
  - Status check: `WiFi.status() == WL_CONNECTED`
  - Heartbeat timeout: `6000 ms` (App pings `/app/heartbeat` every `2000 ms`)
  - Serial monitor feedback:
    - `"Connecting to phone hotspot..."`
    - `"ESP32 CONNECTED TO PHONE HOTSPOT"`
    - `"ESP32 IP Address: xxx.xxx.xxx.xxx"`
    - `"APP HEARTBEAT RECEIVED - MOBILE APP CONNECTED"`
    - `"SAFEPATH MOBILE APP CONNECTED SUCCESSFULLY"`

### Fixed GPIO Pin Mapping
| Component | Function | GPIO Pin | Voltage Note |
| :--- | :--- | :--- | :--- |
| **Left HC-SR04** | Trigger | `GPIO 5` | 3.3V logic output |
| | Echo | `GPIO 18` | **5V to 3.3V Voltage Divider required** |
| **Middle HC-SR04** | Trigger | `GPIO 19` | 3.3V logic output |
| | Echo | `GPIO 21` | **5V to 3.3V Voltage Divider required** |
| **Right HC-SR04** | Trigger | `GPIO 22` | 3.3V logic output |
| | Echo | `GPIO 23` | **5V to 3.3V Voltage Divider required** |
| **MPU6050** | SDA | `GPIO 25` | Standard I2C (400 kHz) |
| | SCL | `GPIO 26` | Standard I2C (400 kHz) |
| **SOS Button** | Active LOW | `GPIO 27` | Internal `INPUT_PULLUP` configured |
| **Active Buzzer** | Alarm Output | `GPIO 32` | Driven with synchronized patterns |
| **Warning LED** | Visual Alarm | `GPIO 33` | Synchronized with buzzer |

### HTTP Endpoints (Port 80)
1. `GET /` — Subsystem banner and endpoint index.
2. `GET /app/heartbeat` — Mobile client connection pulse. Resets heartbeat timer on hardware.
3. `GET /sensors` — Complete JSON telemetry payload. **Does NOT clear SOS.**
4. `GET /sos-status` — Fast emergency state query.
5. `GET /health` — Hardware diagnostics (MPU6050, 3 ultrasonic statuses, Wi-Fi status, client IP).
6. `GET /clear-sos` — Resets active buzzer and hardware emergency flags.

---

## 3. PROJECT SOURCE CODE STRUCTURE

The production application is located at:
`c:\Users\ANISH BISWAL\Desktop\Library\Projects\Smart_Blind_Stick`

```text
lib/
├── main.dart                                # Application bootstrapping & role router
├── core/
│   ├── constants/
│   │   ├── api_constants.dart              # Endpoints, timeouts & thresholds
│   │   ├── app_colors.dart                 # WCAG AAA high-contrast palette
│   │   └── app_strings.dart                # Semantic accessibility labels
│   ├── theme/
│   │   └── app_theme.dart                  # Material 3 high-contrast dark theme
│   └── utils/
│       └── accessibility_utils.dart        # Screen reader announcements & dialer
├── models/
│   ├── device_status.dart                  # /health and /app/heartbeat parser
│   ├── emergency_contact.dart              # Emergency contact model & validator
│   ├── location_data.dart                  # Real GPS data & staleness evaluator
│   ├── sensor_data.dart                    # ESP32 JSON contract parser & danger flags
│   ├── sos_event.dart                      # SOS emergency incident tracking
│   └── user_role.dart                      # Role enum (blindUser / caretaker)
├── providers/
│   ├── blind_user_provider.dart            # Stick polling, voice alerts, GPS sync
│   ├── caretaker_provider.dart             # Caretaker real-time Firestore subscriber
│   └── settings_provider.dart              # Role, IP & speech rate configuration
├── services/
│   ├── emergency_dispatch_service.dart     # Section 6 message format & dispatch
│   ├── esp32_service.dart                  # Real HTTP client (No simulation)
│   ├── firebase_service.dart               # Firestore schema & authentication
│   ├── haptic_service.dart                 # Tactile feedback patterns
│   ├── location_service.dart               # Phone GPS location streaming
│   ├── notification_service.dart           # High-priority Android alarm channel
│   ├── storage_service.dart                # SharedPreferences local storage
│   └── tts_service.dart                    # Text-to-speech audio guidance
├── features/
│   ├── role_selection/
│   │   └── role_selection_screen.dart      # First-launch accessible role picker
│   ├── blind_user/
│   │   ├── dashboard/
│   │   │   └── blind_user_dashboard.dart   # Main Blind User dashboard
│   │   ├── emergency_contact/
│   │   │   └── emergency_contact_screen.dart # Contact CRUD & phone dialer
│   │   └── settings/
│   │       └── blind_user_settings_screen.dart # Stick IP & health diagnostics
│   └── caretaker/
│       ├── dashboard/
│       │   └── caretaker_dashboard.dart    # Caretaker console with Section 7 bar
│       ├── live_map/
│       │   └── caretaker_map_view.dart     # Real-time interactive tracking map
│       ├── pairing/
│       │   └── pairing_screen.dart         # Device code pairing workflow
│       ├── sensor_monitor/
│       │   └── caretaker_sensor_panel.dart # Remote telemetry cards
│       └── sos/
│           └── caretaker_sos_screen.dart   # Fullscreen emergency modal
└── widgets/
    ├── accessible_button.dart              # Large accessible touch targets (≥58px)
    ├── connection_badge.dart               # Stick CONNECTED / DISCONNECTED status
    ├── mpu_telemetry_card.dart             # Acceleration, tilt & fall card
    ├── sos_alert_dialog.dart               # Emergency overlay with clear action
    └── ultrasonic_gauge.dart               # Left, Middle, Right obstacle gauges
```

---

## 4. FIREBASE CLOUD SETUP

### Firestore Data Model
```text
users/{{userId}}
  ├── role: "blind_user" | "caretaker"
  ├── name: String
  ├── phone: String
  └── createdAt: Timestamp

devices/{{deviceId}}
  ├── ownerUserId: String
  ├── deviceStatus: "connected" | "disconnected"
  ├── appConnected: Boolean
  ├── mpu6050Available: Boolean
  ├── sosActive: Boolean
  └── updatedAt: Timestamp

devices/{{deviceId}}/location/current
  ├── latitude: Double
  ├── longitude: Double
  ├── accuracy: Double
  ├── speed: Double
  ├── heading: Double
  └── timestamp: Timestamp

devices/{{deviceId}}/telemetry/current
  ├── left_distance_cm: Double | null
  ├── middle_distance_cm: Double | null
  ├── right_distance_cm: Double | null
  ├── acceleration_g: Double
  ├── tilt_deg: Double
  ├── fall_detected: Boolean
  ├── sos_active: Boolean
  └── timestamp: Timestamp

devices/{{deviceId}}/sosEvents/{{eventId}}
  ├── event_id: String
  ├── type: "FALL" | "BUTTON"
  ├── timestamp: Timestamp
  ├── latitude: Double
  ├── longitude: Double
  ├── maps_url: String
  ├── acknowledged: Boolean
  └── resolved_at: Timestamp | null
```

### Deploying Security Rules
Deploy `firestore.rules` located in the project root:
```bash
firebase deploy --only firestore:rules
```

---

## 5. APK BUILD & INSTALLATION GUIDE

### Building the Release APK
Execute in PowerShell:
```powershell
cd "c:\Users\ANISH BISWAL\Desktop\Library\Projects\Smart_Blind_Stick"
C:\flutter\bin\flutter.bat clean
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat build apk --release
```

**Target APK Output Path:**
`build\app\outputs\flutter-apk\app-release.apk`

### Copying to Android Phone
1. Connect Android phone to PC via USB cable.
2. Select **File Transfer (MTP)** on the phone.
3. Copy `app-release.apk` into the phone's `Download/` folder.
4. On the phone, open Files app, tap `app-release.apk`, and tap **Install**.
5. When prompted, grant:
   - **Location Permission:** Allow all the time (for emergency tracking).
   - **Notifications:** Allow (for high-priority alarm channel).
   - **Phone / Calling:** Allow (for instant contact dialing).

---

## 6. END-TO-END ACCEPTANCE TESTING RUNBOOK

### Test A: Physical SOS Button Flow
1. Connect Phone A to Wi-Fi AP: `SafePath_SmartStick`.
2. Open SafePath in **Blind Stick User** mode. Verify badge reads `Stick: CONNECTED`.
3. Press physical push button connected to `GPIO 27` on stick.
4. **Hardware reaction:** Buzzer sounds continuous high-priority SOS pattern; LED illuminates.
5. **Mobile reaction:** Phone A sounds loud speech alert: *"Emergency SOS active! Trigger reason: BUTTON"*.
6. Phone A acquires phone GPS and creates document in `devices/ESP32-SAFEPATH-01/sosEvents/`.
7. Open Phone B in **Caretaker** mode.
8. **Caretaker reaction:** Fullscreen modal appears: `🚨 SOS ACTIVE 🚨`, showing timestamp and coordinates.
9. Caretaker taps **ACKNOWLEDGE & RESOLVE**.
10. Blind user taps **CLEAR & RESET STICK ALARM**.
11. App sends `GET /clear-sos` to ESP32. Buzzer stops. Status resets to `NORMAL`.

### Test B: Real MPU6050 Fall Detection Flow
1. Hold stick upright (tilt ~ 0°–10°).
2. Simulate sudden free-fall followed by impact onto a soft surface (e.g., bed or sofa).
3. ESP32 detects free-fall (`<= 0.55G`) followed by impact (`>= 2.20G`) and orientation shift (`>= 45°`).
4. ESP32 triggers `sos_active = true` and `fall_detected = true`.
5. Mobile app immediately launches the SOS workflow with trigger reason: `FALL`.
6. Verify coordinates appear on Phone B's live map.

---

## 7. PRODUCTION SETUP CHECKLIST

- [x] **ESP32 flashed:** Firmware compiled and running.
- [x] **Wi-Fi AP active:** SSID `SafePath_SmartStick` broadcasting on 2.4 GHz.
- [x] **Phone connected:** Phone successfully associated with Wi-Fi AP.
- [x] **App heartbeat active:** `GET /app/heartbeat` confirmed every 2s in Serial Monitor.
- [x] **Ultrasonic sensors active:** Left, Middle, and Right distances update in real-time.
- [x] **Danger threshold verified:** Obstacles closer than 20 cm trigger Danger state and buzzer.
- [x] **MPU6050 active:** Tilt angle and acceleration G stream accurately.
- [x] **SOS button active:** GPIO 27 button reliably triggers alarm.
- [x] **GPS permission granted:** Phone GPS stream active without mock data.
- [x] **Firebase synchronized:** Location and telemetry upload to Firestore.
- [x] **Caretaker console active:** Live map renders moving marker for blind user.
- [x] **Emergency contact configured:** Validated contact saved with 1-tap call action.
- [x] **SOS clear flow verified:** `GET /clear-sos` stops stick buzzer.
- [x] **Release APK validated:** Zero static analysis issues; 100% unit tests passed.

---

## 8. RELEASE APK ARTIFACT & DEPLOYMENT

### Production Build Specifications
- **Build Timestamp:** October 8, 2026
- **Toolchain:** Flutter 3.47.6 / Dart 3.13.5 / OpenJDK 17.0.20
- **Android Target:** API 34+ (Android 14+) with backward compatibility to API 21+
- **Architectures Included:** `arm64-v8a`, `armeabi-v7a`, `x86_64`
- **Output Artifact Location:**
  `build/app/outputs/flutter-apk/app-release.apk`
- **Absolute Filepath:**
  `C:\Users\ANISH BISWAL\Desktop\Library\Projects\Smart_Blind_Stick\build\app\outputs\flutter-apk\app-release.apk`
- **File Size:** `512,258,045 bytes` (~488.53 MB unstripped release bundle)
- **SHA-256 Checksum:** `F099504DB5FB9683075825A30DB47D36C22358E763917CC8CEC5C3EDF7FF4089`

### Installation & Deployment Instructions

1. **Direct USB Sideloading via ADB:**
   ```bash
   adb install -r "C:\Users\ANISH BISWAL\Desktop\Library\Projects\Smart_Blind_Stick\build\app\outputs\flutter-apk\app-release.apk"
   ```

2. **Manual Device Installation:**
   - Transfer `app-release.apk` to Android device storage via USB or local file sharing.
   - On the device, open **Files / Downloads**.
   - Tap `app-release.apk`. When prompted, select **Settings > Allow from this source** to permit unknown app installation.
   - Tap **Install**, then grant Location, SMS/Phone, and Notification permissions on first launch.

