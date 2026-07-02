/**
 * Smart Irrigation System — Firmware V2 ⏳ ĐANG PHÁT TRIỂN
 *
 * Bổ sung so với V1:
 *   ✅ Chế độ AUTO (ngưỡng độ ẩm tự động mở/đóng van + bơm)
 *   ✅ Giao thức lệnh JSON qua Serial (chuẩn bị cho Bluetooth/UART)
 *   ✅ State machine: MANUAL / AUTO / EMERGENCY
 *   ✅ DHT22 — đọc nhiệt độ & độ ẩm không khí
 *   ⏳ Lịch tưới định kỳ (TODO)
 *   ⏳ Lưu cài đặt vào EEPROM (TODO)
 *
 * Board : ESP32 WROOM-32
 */

#include "../include/pins.h"
#include "../include/config.h"
#include <DHT.h>
#include <ArduinoJson.h>

// ─── Enum trạng thái ───────────────────────────────────────
enum SystemMode { MODE_MANUAL, MODE_AUTO, MODE_EMERGENCY };
SystemMode currentMode = MODE_MANUAL;

// ─── Biến trạng thái ───────────────────────────────────────
bool valveState[NUM_VALVES]     = {false, false, false, false};
bool pumpState                  = false;
unsigned long pumpStartTime     = 0;
unsigned long lastSensorRead    = 0;
int moisturePct[NUM_VALVES]     = {0, 0, 0, 0};
float waterLevelPct             = 0.0f;
float airTemp                   = 0.0f;
float airHumidity               = 0.0f;

// ─── DHT22 ─────────────────────────────────────────────────
#define DHTTYPE DHT22
DHT dht(DHT_PIN, DHTTYPE);

// ─── Prototype ─────────────────────────────────────────────
void openValve(int idx);
void closeValve(int idx);
void closeAllValves();
void setPump(bool on);
int  readMoisture(int idx);
float readWaterLevel();
void readAllSensors();
void runAutoMode();
void handleSerial();
void sendStatusJson();
void processJsonCommand(const String& json);

// ───────────────────────────────────────────────────────────
void setup() {
  Serial.begin(SERIAL_BAUD);
  Serial.println(F("{\"event\":\"boot\",\"fw\":\"" FW_VERSION "\"}"));

  // Relay init (Active LOW → HIGH = OFF)
  int relayPins[] = {RELAY_VALVE_1, RELAY_VALVE_2, RELAY_VALVE_3, RELAY_VALVE_4, RELAY_PUMP};
  for (int p : relayPins) { pinMode(p, OUTPUT); digitalWrite(p, HIGH); }

  // GPIO init
  pinMode(WATER_LEVEL_TRIG, OUTPUT);
  pinMode(WATER_LEVEL_ECHO, INPUT);
  pinMode(BTN_MANUAL_MODE, INPUT_PULLUP);
  pinMode(BTN_STOP_ALL, INPUT_PULLUP);
  pinMode(LED_STATUS, OUTPUT);
  pinMode(LED_AUTO_MODE, OUTPUT);

  dht.begin();
  readAllSensors();

  Serial.println(F("{\"event\":\"ready\",\"mode\":\"MANUAL\"}"));
}

// ───────────────────────────────────────────────────────────
void loop() {
  // Xử lý nút bấm vật lý
  if (digitalRead(BTN_STOP_ALL) == LOW) {
    currentMode = MODE_EMERGENCY;
    closeAllValves();
    setPump(false);
    Serial.println(F("{\"event\":\"emergency\",\"source\":\"button\"}"));
    delay(1000);
    currentMode = MODE_MANUAL;
  }

  if (digitalRead(BTN_MANUAL_MODE) == LOW) {
    currentMode = (currentMode == MODE_AUTO) ? MODE_MANUAL : MODE_AUTO;
    digitalWrite(LED_AUTO_MODE, currentMode == MODE_AUTO ? HIGH : LOW);
    Serial.print(F("{\"event\":\"mode_change\",\"mode\":\""));
    Serial.print(currentMode == MODE_AUTO ? F("AUTO") : F("MANUAL"));
    Serial.println(F("\"}"));
    delay(500);
  }

  // Đọc cảm biến định kỳ
  if (millis() - lastSensorRead >= SENSOR_READ_INTERVAL_MS) {
    readAllSensors();
    sendStatusJson();
    lastSensorRead = millis();
  }

  // Chế độ AUTO
  if (currentMode == MODE_AUTO) runAutoMode();

  // Bảo vệ timeout bơm
  if (pumpState && (millis() - pumpStartTime >= PUMP_MAX_ON_TIME_MS)) {
    Serial.println(F("{\"event\":\"pump_timeout\",\"action\":\"force_off\"}"));
    setPump(false);
    closeAllValves();
  }

  // Xử lý lệnh JSON từ Serial
  if (Serial.available()) handleSerial();

  // LED trạng thái
  digitalWrite(LED_STATUS, (millis() / (currentMode == MODE_AUTO ? 250 : 1000)) % 2);
}

// ─── Chế độ AUTO ───────────────────────────────────────────
void runAutoMode() {
  // Kiểm tra mực nước an toàn
  if (waterLevelPct <= WATER_LEVEL_CRITICAL_PCT) {
    if (pumpState) { setPump(false); closeAllValves(); }
    return;
  }

  bool anyNeedsWater = false;
  for (int i = 0; i < NUM_VALVES; i++) {
    if (moisturePct[i] < (AUTO_MOISTURE_LOW - MOISTURE_HYSTERESIS)) {
      if (!valveState[i]) openValve(i);
      anyNeedsWater = true;
    } else if (moisturePct[i] >= AUTO_MOISTURE_HIGH) {
      if (valveState[i]) closeValve(i);
    }
  }

  // Bơm chạy khi có ít nhất 1 van mở
  if (anyNeedsWater && !pumpState) setPump(true);
  else if (!anyNeedsWater && pumpState) setPump(false);
}

// ─── Đọc tất cả cảm biến ───────────────────────────────────
void readAllSensors() {
  for (int i = 0; i < NUM_VALVES; i++) moisturePct[i] = readMoisture(i);
  waterLevelPct = readWaterLevel();
  airTemp     = dht.readTemperature();
  airHumidity = dht.readHumidity();
}

// ─── Gửi JSON trạng thái ───────────────────────────────────
void sendStatusJson() {
  StaticJsonDocument<512> doc;
  doc["event"] = "status";
  doc["mode"]  = (currentMode == MODE_AUTO) ? "AUTO" : "MANUAL";
  doc["pump"]  = pumpState;
  doc["water_level"] = waterLevelPct;
  doc["temp"]  = airTemp;
  doc["humidity"] = airHumidity;
  JsonArray valves   = doc.createNestedArray("valves");
  JsonArray moisture = doc.createNestedArray("moisture");
  for (int i = 0; i < NUM_VALVES; i++) {
    valves.add(valveState[i]);
    moisture.add(moisturePct[i]);
  }
  serializeJson(doc, Serial);
  Serial.println();
}

// ─── Xử lý lệnh JSON qua Serial ────────────────────────────
void handleSerial() {
  String raw = Serial.readStringUntil('\n');
  raw.trim();
  if (raw.startsWith("{")) {
    processJsonCommand(raw);
  } else {
    // Hỗ trợ lệnh text đơn giản cho debug
    raw.toUpperCase();
    if      (raw == "S")  sendStatusJson();
    else if (raw == "X")  { closeAllValves(); setPump(false); }
    else if (raw == "AUTO")   { currentMode = MODE_AUTO;   digitalWrite(LED_AUTO_MODE, HIGH); }
    else if (raw == "MANUAL") { currentMode = MODE_MANUAL; digitalWrite(LED_AUTO_MODE, LOW); }
  }
}

void processJsonCommand(const String& json) {
  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, json) != DeserializationError::Ok) {
    Serial.println(F("{\"error\":\"invalid_json\"}"));
    return;
  }
  const char* cmd = doc["cmd"];
  if (!cmd) return;

  String c = String(cmd);
  if (c == "open_valve") {
    int idx = doc["valve"] | -1;
    if (idx >= 1 && idx <= NUM_VALVES) openValve(idx - 1);
  } else if (c == "close_valve") {
    int idx = doc["valve"] | -1;
    if (idx >= 1 && idx <= NUM_VALVES) closeValve(idx - 1);
  } else if (c == "pump") {
    setPump(doc["state"] | false);
  } else if (c == "set_mode") {
    String mode = doc["mode"] | "manual";
    currentMode = (mode == "auto") ? MODE_AUTO : MODE_MANUAL;
    digitalWrite(LED_AUTO_MODE, currentMode == MODE_AUTO ? HIGH : LOW);
  } else if (c == "stop_all") {
    closeAllValves();
    setPump(false);
  } else if (c == "status") {
    sendStatusJson();
  }
}

// ─── Hàm điều khiển ────────────────────────────────────────
void openValve(int idx) {
  int pins[] = {RELAY_VALVE_1, RELAY_VALVE_2, RELAY_VALVE_3, RELAY_VALVE_4};
  digitalWrite(pins[idx], LOW);
  valveState[idx] = true;
}

void closeValve(int idx) {
  int pins[] = {RELAY_VALVE_1, RELAY_VALVE_2, RELAY_VALVE_3, RELAY_VALVE_4};
  digitalWrite(pins[idx], HIGH);
  valveState[idx] = false;
}

void closeAllValves() {
  for (int i = 0; i < NUM_VALVES; i++) closeValve(i);
}

void setPump(bool on) {
  digitalWrite(RELAY_PUMP, on ? LOW : HIGH);
  pumpState = on;
  if (on) pumpStartTime = millis();
}

int readMoisture(int idx) {
  int adcPins[] = {SOIL_MOISTURE_1, SOIL_MOISTURE_2, SOIL_MOISTURE_3, SOIL_MOISTURE_4};
  int raw = analogRead(adcPins[idx]);
  return constrain(map(raw, SOIL_DRY_VALUE, SOIL_WET_VALUE, 0, 100), 0, 100);
}

float readWaterLevel() {
  digitalWrite(WATER_LEVEL_TRIG, LOW);  delayMicroseconds(2);
  digitalWrite(WATER_LEVEL_TRIG, HIGH); delayMicroseconds(10);
  digitalWrite(WATER_LEVEL_TRIG, LOW);
  long dur = pulseIn(WATER_LEVEL_ECHO, HIGH, 30000);
  float dist = dur * 0.0343f / 2.0f;
  return constrain(((TANK_HEIGHT_CM - dist) / TANK_HEIGHT_CM) * 100.0f, 0.0f, 100.0f);
}
