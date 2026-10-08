/*
 * ============================================================
 * SafePath Smart Blind Stick - Production ESP32 Firmware
 * Architecture: ESP32 Wi-Fi Station (WIFI_STA) Mode
 * Connecting to Blind User's Mobile Hotspot
 * ============================================================
 *
 * PHONE HOTSPOT ARCHITECTURE:
 * 1. Blind User Phone has:
 *      - Mobile Data  -> ON  (Internet for Firebase, Firestore, FCM, SMS)
 *      - GPS          -> ON  (High-accuracy phone coordinates)
 *      - Wi-Fi Hotspot-> ON  (2.4 GHz local AP for the stick)
 * 2. ESP32 operates in WIFI_STA mode and connects to the phone hotspot.
 * 3. ESP32 serves the local HTTP REST API on port 80 at its hotspot IP.
 * 4. The ESP32 does NOT have GPS. When an SOS occurs (button or fall),
 *    the phone polls or is notified, captures phone GPS, and uploads to Firebase.
 * 5. Local safety (ultrasonics, MPU6050 fall detection, buzzer, LED, button)
 *    is 100% NON-BLOCKING and operates continuously even if Wi-Fi is lost.
 *
 * HARDWARE PIN MAPPING:
 *   LEFT ULTRASONIC   : TRIG GPIO 5  / ECHO GPIO 18
 *   MIDDLE ULTRASONIC : TRIG GPIO 19 / ECHO GPIO 21
 *   RIGHT ULTRASONIC  : TRIG GPIO 22 / ECHO GPIO 23
 *   MPU6050           : SDA  GPIO 25 / SCL  GPIO 26
 *   SOS BUTTON        : GPIO 27 (INPUT_PULLUP)
 *   BUZZER            : GPIO 32
 *   LED               : GPIO 33
 *
 * HTTP API ENDPOINTS:
 *   GET /              - Basic device identification
 *   GET /sensors       - Full sensor telemetry JSON
 *   GET /sos-status    - Lightweight SOS status JSON
 *   GET /app/heartbeat - Mobile app registration ping
 *   GET /health        - Subsystem diagnostic status
 *   GET /clear-sos     - Reset hardware SOS alarm
 * ============================================================
 */

#include <WiFi.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <ArduinoJson.h>
#include <math.h>

// ============================================================
// 1. PHONE HOTSPOT CREDENTIALS (WIFI_STA MODE)
// ============================================================
// Change these credentials to match the blind user's mobile hotspot.
// Hotspot MUST be set to 2.4 GHz band in phone settings.
const char* WIFI_SSID     = "PHONE_HOTSPOT_NAME";
const char* WIFI_PASSWORD = "PHONE_HOTSPOT_PASSWORD";

// Local HTTP Web Server
WebServer server(80);

// ============================================================
// 2. FIXED HARDWARE PIN DEFINITIONS
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
// 3. SYSTEM TIMING & SAFETY THRESHOLDS
// ============================================================
#define DANGER_THRESHOLD_CM         20.0f
#define ULTRASONIC_TIMEOUT_US       30000UL

#define ULTRASONIC_UPDATE_MS        100UL
#define MPU_UPDATE_MS               20UL
#define FALL_COOLDOWN_MS            8000UL
#define APP_HEARTBEAT_TIMEOUT_MS    6000UL
#define WIFI_RECONNECT_INTERVAL_MS  5000UL

// MPU6050 Fall Detection Parameters
#define FREEFALL_THRESHOLD_G        0.55f
#define IMPACT_THRESHOLD_G          2.20f
#define HARD_IMPACT_THRESHOLD_G     3.00f
#define POST_FALL_TILT_DEG          45.0f
#define FALL_SEQUENCE_WINDOW_MS     900UL

// ============================================================
// 4. GLOBAL SENSORS & STATE
// ============================================================
Adafruit_MPU6050 mpu;
bool mpuFound = false;

// Ultrasonic Distances (cm, -1 = no echo)
float leftDistance   = -1.0f;
float middleDistance = -1.0f;
float rightDistance  = -1.0f;

// MPU6050 Readings
float ax = 0.0f, ay = 0.0f, az = 0.0f;
float gx = 0.0f, gy = 0.0f, gz = 0.0f;
float temperature = 0.0f;
float totalAccelerationG = 1.0f;

// Fall Detection State
bool fallDetected = false;
unsigned long lastFallTime = 0;
bool freefallDetected = false;
unsigned long freefallTime = 0;

// Dynamic Orientation Baseline
float baselineAx = 0.0f, baselineAy = 0.0f, baselineAz = 1.0f;
bool orientationBaselineValid = false;

// SOS State
bool sosActive = false;
bool sosButtonEvent = false;

// Connection Tracking
unsigned long lastAppHeartbeat = 0;
bool lastMobileWiFiConnected = false;
bool lastAppConnected = false;
unsigned long lastWiFiReconnectAttempt = 0;
bool mdnsStarted = false;

// Loop Timers
unsigned long lastUltrasonicUpdate = 0;
unsigned long lastMPUUpdate = 0;

// Alarm Pattern Engine
enum AlarmPattern {
    PATTERN_OFF,
    PATTERN_LEFT,
    PATTERN_MIDDLE,
    PATTERN_RIGHT,
    PATTERN_SOS
};

AlarmPattern activePattern = PATTERN_OFF;
int patternStep = 0;
unsigned long patternTimer = 0;
bool alarmOutputState = false;

// ============================================================
// 5. HARDWARE DRIVER IMPLEMENTATIONS
// ============================================================

void setAlarmOutput(bool enable)
{
    alarmOutputState = enable;
    digitalWrite(BUZZER, enable ? HIGH : LOW);
    digitalWrite(LED_PIN, enable ? HIGH : LOW);
}

float measureDistance(uint8_t trigPin, uint8_t echoPin)
{
    digitalWrite(trigPin, LOW);
    delayMicroseconds(2);
    digitalWrite(trigPin, HIGH);
    delayMicroseconds(10);
    digitalWrite(trigPin, LOW);

    unsigned long duration = pulseIn(echoPin, HIGH, ULTRASONIC_TIMEOUT_US);
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
    leftDistance   = measureDistance(LEFT_TRIG, LEFT_ECHO);
    delay(2);
    middleDistance = measureDistance(MIDDLE_TRIG, MIDDLE_ECHO);
    delay(2);
    rightDistance  = measureDistance(RIGHT_TRIG, RIGHT_ECHO);
}

float calculateTiltFromGravity()
{
    if (!orientationBaselineValid) return 0.0f;

    float currentMag = sqrtf(ax * ax + ay * ay + az * az);
    float baselineMag = sqrtf(baselineAx * baselineAx + baselineAy * baselineAy + baselineAz * baselineAz);

    if (currentMag < 0.5f || baselineMag < 0.5f) return 0.0f;

    float dot = (ax * baselineAx + ay * baselineAy + az * baselineAz) / (currentMag * baselineMag);
    if (dot > 1.0f) dot = 1.0f;
    if (dot < -1.0f) dot = -1.0f;

    return acosf(dot) * 180.0f / PI;
}

void updateOrientationBaseline()
{
    if (!mpuFound) return;

    float gyroMagnitude = sqrtf(gx * gx + gy * gy + gz * gz);
    if (totalAccelerationG > 0.85f && totalAccelerationG < 1.15f && gyroMagnitude < 0.70f) {
        if (!orientationBaselineValid) {
            baselineAx = ax;
            baselineAy = ay;
            baselineAz = az;
            orientationBaselineValid = true;
        } else {
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

    activePattern = PATTERN_SOS;
    patternStep = 0;
    patternTimer = millis();
    setAlarmOutput(true);
}

void updateMPU6050()
{
    if (!mpuFound) return;

    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    ax = a.acceleration.x;
    ay = a.acceleration.y;
    az = a.acceleration.z;

    gx = g.gyro.x;
    gy = g.gyro.y;
    gz = g.gyro.z;

    temperature = temp.temperature;

    float totalAccelMps2 = sqrtf(ax * ax + ay * ay + az * az);
    totalAccelerationG = totalAccelMps2 / 9.80665f;

    updateOrientationBaseline();

    unsigned long now = millis();

    // Stage 1: Detect free-fall (stick falling)
    if (totalAccelerationG <= FREEFALL_THRESHOLD_G) {
        if (!freefallDetected) {
            freefallDetected = true;
            freefallTime = now;
        }
    }

    // Stage 2: Detect impact following free-fall
    if (freefallDetected) {
        if (now - freefallTime <= FALL_SEQUENCE_WINDOW_MS) {
            if (totalAccelerationG >= IMPACT_THRESHOLD_G) {
                float tilt = calculateTiltFromGravity();
                if (tilt >= POST_FALL_TILT_DEG || totalAccelerationG >= HARD_IMPACT_THRESHOLD_G) {
                    if (now - lastFallTime >= FALL_COOLDOWN_MS) {
                        triggerSOS("FALL");
                    }
                    freefallDetected = false;
                }
            }
        } else {
            freefallDetected = false;
        }
    }
}

void checkSOSButton()
{
    static int lastButtonState = HIGH;
    static unsigned long lastDebounceTime = 0;
    const unsigned long debounceDelay = 50;

    int reading = digitalRead(SOS_BUTTON);

    if (reading != lastButtonState) {
        lastDebounceTime = millis();
    }

    if ((millis() - lastDebounceTime) > debounceDelay) {
        if (reading == LOW && !sosButtonEvent) {
            sosButtonEvent = true;
            Serial.println();
            Serial.println("================================");
            Serial.println("PHYSICAL SOS BUTTON PRESSED");
            Serial.println("================================");
            triggerSOS("BUTTON");
        }
    }
    lastButtonState = reading;
}

// ============================================================
// 6. PATTERN & BEHAVIOR ENGINE
// ============================================================

void updateBuzzerLEDState()
{
    if (sosActive) {
        activePattern = PATTERN_SOS;
    } else {
        bool middleDanger = (middleDistance >= 0.0f && middleDistance < DANGER_THRESHOLD_CM);
        bool leftDanger   = (leftDistance >= 0.0f   && leftDistance < DANGER_THRESHOLD_CM);
        bool rightDanger  = (rightDistance >= 0.0f  && rightDistance < DANGER_THRESHOLD_CM);

        if (middleDanger) {
            activePattern = PATTERN_MIDDLE;
        } else if (leftDanger) {
            activePattern = PATTERN_LEFT;
        } else if (rightDanger) {
            activePattern = PATTERN_RIGHT;
        } else {
            activePattern = PATTERN_OFF;
        }
    }

    unsigned long now = millis();

    switch (activePattern) {
        case PATTERN_OFF:
            patternStep = 0;
            setAlarmOutput(false);
            break;

        case PATTERN_MIDDLE:
            // Continuous fast beep (100ms ON, 100ms OFF)
            if (patternStep == 0) {
                setAlarmOutput(true);
                patternStep = 1;
                patternTimer = now;
            } else if (patternStep == 1 && (now - patternTimer >= 100)) {
                setAlarmOutput(false);
                patternStep = 2;
                patternTimer = now;
            } else if (patternStep == 2 && (now - patternTimer >= 100)) {
                patternStep = 0;
            }
            break;

        case PATTERN_LEFT:
            // Single pulse pattern (150ms ON, 250ms OFF)
            if (patternStep == 0) {
                setAlarmOutput(true);
                patternStep = 1;
                patternTimer = now;
            } else if (patternStep == 1 && (now - patternTimer >= 150)) {
                setAlarmOutput(false);
                patternStep = 2;
                patternTimer = now;
            } else if (patternStep == 2 && (now - patternTimer >= 250)) {
                patternStep = 0;
            }
            break;

        case PATTERN_RIGHT:
            // Double pulse pattern (80ms ON, 80ms OFF, 80ms ON, 300ms OFF)
            if (patternStep == 0) {
                setAlarmOutput(true);
                patternStep = 1;
                patternTimer = now;
            } else if (patternStep == 1 && (now - patternTimer >= 80)) {
                setAlarmOutput(false);
                patternStep = 2;
                patternTimer = now;
            } else if (patternStep == 2 && (now - patternTimer >= 80)) {
                setAlarmOutput(true);
                patternStep = 3;
                patternTimer = now;
            } else if (patternStep == 3 && (now - patternTimer >= 80)) {
                setAlarmOutput(false);
                patternStep = 4;
                patternTimer = now;
            } else if (patternStep == 4 && (now - patternTimer >= 300)) {
                patternStep = 0;
            }
            break;

        case PATTERN_SOS:
            // Urgent continuous SOS alarm (250ms ON, 100ms OFF)
            if (patternStep == 0) {
                setAlarmOutput(true);
                patternStep = 1;
                patternTimer = now;
            } else if (patternStep == 1 && (now - patternTimer >= 250)) {
                setAlarmOutput(false);
                patternStep = 2;
                patternTimer = now;
            } else if (patternStep == 2 && (now - patternTimer >= 100)) {
                patternStep = 0;
            }
            break;
    }
}

// ============================================================
// 7. PHONE HOTSPOT & APP CONNECTION STATE
// ============================================================

bool isMobileWiFiConnected()
{
    return WiFi.status() == WL_CONNECTED;
}

bool isMobileAppConnected()
{
    return isMobileWiFiConnected() &&
           (millis() - lastAppHeartbeat <= APP_HEARTBEAT_TIMEOUT_MS);
}

void updateMobileConnectionStatus()
{
    bool wifiConnected = isMobileWiFiConnected();
    bool appConnected  = isMobileAppConnected();

    if (wifiConnected != lastMobileWiFiConnected) {
        if (wifiConnected) {
            Serial.println();
            Serial.println("ESP32 CONNECTED TO PHONE HOTSPOT");
            Serial.print("ESP32 IP Address: ");
            Serial.println(WiFi.localIP());

            if (!mdnsStarted && MDNS.begin("safepath-stick")) {
                MDNS.addService("http", "tcp", 80);
                mdnsStarted = true;
                Serial.println("mDNS active: http://safepath-stick.local");
            }
        } else {
            Serial.println();
            Serial.println("ESP32 DISCONNECTED FROM PHONE HOTSPOT");
        }
        lastMobileWiFiConnected = wifiConnected;
    }

    if (appConnected != lastAppConnected) {
        if (appConnected) {
            Serial.println();
            Serial.println("SAFEPATH MOBILE APP CONNECTED SUCCESSFULLY");
        } else if (wifiConnected) {
            Serial.println();
            Serial.println("Wi-Fi connected to phone hotspot, but app heartbeat is missing");
        } else {
            Serial.println();
            Serial.println("SAFEPATH MOBILE APP DISCONNECTED");
        }
        lastAppConnected = appConnected;
    }
}

// Non-blocking reconnect to phone hotspot if connection drops
void handleWiFiReconnection()
{
    if (WiFi.status() != WL_CONNECTED) {
        unsigned long now = millis();
        if (now - lastWiFiReconnectAttempt >= WIFI_RECONNECT_INTERVAL_MS) {
            lastWiFiReconnectAttempt = now;
            Serial.println("Reconnecting to phone hotspot...");
            WiFi.disconnect();
            WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
        }
    }
}

// ============================================================
// 8. REST API ROUTE HANDLERS
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

    doc["left_sensor_status"]   = (leftDistance >= 0) ? "ok" : "no_echo";
    doc["middle_sensor_status"] = (middleDistance >= 0) ? "ok" : "no_echo";
    doc["right_sensor_status"]  = (rightDistance >= 0) ? "ok" : "no_echo";

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

    doc["fall_detected"] = fallDetected;
    doc["sos_active"] = sosActive;
    doc["sos_pressed"] = sosButtonEvent;

    doc["wifi_connected"] = isMobileWiFiConnected();
    doc["app_connected"] = isMobileAppConnected();
    doc["connected_clients"] = isMobileWiFiConnected() ? 1 : 0;

    doc["uptime_ms"] = millis();
    doc["free_heap"] = ESP.getFreeHeap();
    doc["wifi_rssi"] = isMobileWiFiConnected() ? WiFi.RSSI() : 0;
    doc["ip"] = isMobileWiFiConnected() ? WiFi.localIP().toString() : "0.0.0.0";
}

void handleRoot()
{
    StaticJsonDocument<256> doc;
    doc["device"] = "SafePath Smart Blind Stick";
    doc["firmware_mode"] = "WIFI_STA (Phone Hotspot)";
    doc["device_id"] = "ESP32-SAFEPATH-01";
    doc["wifi_connected"] = isMobileWiFiConnected();
    doc["ip"] = isMobileWiFiConnected() ? WiFi.localIP().toString() : "0.0.0.0";

    String response;
    serializeJson(doc, response);
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", response);
}

void handleSensors()
{
    StaticJsonDocument<1536> doc;
    addSensorData(doc);

    String response;
    serializeJson(doc, response);

    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", response);
}

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

void handleAppHeartbeat()
{
    lastAppHeartbeat = millis();

    Serial.println("APP HEARTBEAT RECEIVED - MOBILE APP CONNECTED");

    StaticJsonDocument<512> doc;
    doc["status"] = "app_connected";
    doc["device_id"] = "ESP32-SAFEPATH-01";
    doc["sos_active"] = sosActive;
    doc["ip"] = isMobileWiFiConnected() ? WiFi.localIP().toString() : "0.0.0.0";

    String response;
    serializeJson(doc, response);

    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", response);
}

void handleClearSOS()
{
    sosActive = false;
    fallDetected = false;
    sosButtonEvent = false;

    Serial.println();
    Serial.println("==========================================");
    Serial.println("SOS ALARM CLEARED VIA MOBILE APP /clear-sos");
    Serial.println("==========================================");

    setAlarmOutput(false);
    activePattern = PATTERN_OFF;
    patternStep = 0;

    StaticJsonDocument<256> doc;
    doc["status"] = "cleared";
    doc["sos_active"] = false;

    String response;
    serializeJson(doc, response);

    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", response);
}

void handleHealth()
{
    StaticJsonDocument<512> doc;
    doc["status"] = "ok";
    doc["device_id"] = "ESP32-SAFEPATH-01";
    doc["mpu6050_ok"] = mpuFound;
    doc["left_ultrasonic_ok"]   = (leftDistance >= 0);
    doc["middle_ultrasonic_ok"] = (middleDistance >= 0);
    doc["right_ultrasonic_ok"]  = (rightDistance >= 0);
    doc["mobile_wifi_connected"] = isMobileWiFiConnected();
    doc["mobile_app_connected"]  = isMobileAppConnected();
    doc["free_heap"] = ESP.getFreeHeap();
    doc["ip"] = isMobileWiFiConnected() ? WiFi.localIP().toString() : "0.0.0.0";

    String response;
    serializeJson(doc, response);

    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", response);
}

// ============================================================
// 9. SETUP
// ============================================================

void setup()
{
    Serial.begin(115200);
    delay(1000);

    Serial.println();
    Serial.println("==========================================");
    Serial.println(" SafePath Smart Blind Stick - WIFI_STA");
    Serial.println("==========================================");

    // Pin Modes
    pinMode(LEFT_TRIG, OUTPUT);
    pinMode(LEFT_ECHO, INPUT);
    pinMode(MIDDLE_TRIG, OUTPUT);
    pinMode(MIDDLE_ECHO, INPUT);
    pinMode(RIGHT_TRIG, OUTPUT);
    pinMode(RIGHT_ECHO, INPUT);

    pinMode(SOS_BUTTON, INPUT_PULLUP);
    pinMode(BUZZER, OUTPUT);
    pinMode(LED_PIN, OUTPUT);

    setAlarmOutput(false);

    // Initialize MPU6050 on custom I2C pins (SDA=25, SCL=26)
    Wire.begin(MPU_SDA, MPU_SCL);
    if (mpu.begin()) {
        mpuFound = true;
        Serial.println("MPU6050 initialized successfully.");
        mpu.setAccelerometerRange(MPU6050_RANGE_8_G);
        mpu.setGyroRange(MPU6050_RANGE_500_DEG);
        mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
    } else {
        mpuFound = false;
        Serial.println("WARNING: MPU6050 not found on SDA 25 / SCL 26.");
    }

    // --------------------------------------------------------
    // Connect to Blind User Phone Hotspot in Station Mode
    // --------------------------------------------------------
    Serial.println();
    Serial.println("Connecting to phone hotspot...");
    Serial.print("Target Hotspot SSID: ");
    Serial.println(WIFI_SSID);

    WiFi.mode(WIFI_STA);
    WiFi.disconnect(true);
    delay(100);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    // Non-blocking wait for initial connection (up to 4s)
    unsigned long startAttempt = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - startAttempt < 4000) {
        delay(200);
        Serial.print(".");
    }
    Serial.println();

    if (WiFi.status() == WL_CONNECTED) {
        Serial.println();
        Serial.println("ESP32 CONNECTED TO PHONE HOTSPOT");
        Serial.print("ESP32 IP Address: ");
        Serial.println(WiFi.localIP());

        if (MDNS.begin("safepath-stick")) {
            MDNS.addService("http", "tcp", 80);
            mdnsStarted = true;
            Serial.println("mDNS active: http://safepath-stick.local");
        }
    } else {
        Serial.println("Hotspot not connected yet. Will reconnect in background loop.");
        Serial.println("Local sensor and safety loops are ACTIVE.");
    }

    // --------------------------------------------------------
    // Register HTTP Routes
    // --------------------------------------------------------
    server.on("/", HTTP_GET, handleRoot);
    server.on("/sensors", HTTP_GET, handleSensors);
    server.on("/sos-status", HTTP_GET, handleSOSStatus);
    server.on("/app/heartbeat", HTTP_GET, handleAppHeartbeat);
    server.on("/health", HTTP_GET, handleHealth);
    server.on("/clear-sos", HTTP_GET, handleClearSOS);

    server.begin();

    // Startup Hardware Beep & LED Test
    setAlarmOutput(true);
    delay(250);
    setAlarmOutput(false);
    delay(200);

    Serial.println();
    Serial.println("==========================================");
    Serial.println("            HARDWARE READY");
    Serial.println("==========================================");
}

// ============================================================
// 10. MAIN NON-BLOCKING LOOP
// ============================================================

void loop()
{
    unsigned long now = millis();

    // 1. Handle incoming HTTP requests
    server.handleClient();

    // 2. Physical SOS button check
    checkSOSButton();

    // 3. MPU6050 reading & Fall detection (50 Hz = 20ms)
    if (now - lastMPUUpdate >= MPU_UPDATE_MS) {
        lastMPUUpdate = now;
        updateMPU6050();
    }

    // 4. Ultrasonic distance measurements (10 Hz = 100ms)
    if (now - lastUltrasonicUpdate >= ULTRASONIC_UPDATE_MS) {
        lastUltrasonicUpdate = now;
        updateUltrasonicSensors();
    }

    // 5. Buzzer & LED pattern engine
    updateBuzzerLEDState();

    // 6. Monitor Wi-Fi connection and mobile app heartbeat
    updateMobileConnectionStatus();

    // 7. Non-blocking Wi-Fi auto-reconnection
    handleWiFiReconnection();
}
