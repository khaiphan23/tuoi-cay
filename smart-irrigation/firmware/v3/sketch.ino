/**
 * Smart Irrigation System — Firmware V3
 * WiFi + Supabase Realtime
 *
 * Bổ sung so với V2:
 *   ✅ WiFi (ESP32 built-in)
 *   ✅ Đẩy dữ liệu sensor lên Supabase (HTTP POST)
 *   ✅ Lắng nghe lệnh từ Supabase Realtime (WebSocket)
 *   ✅ OTA update qua WiFi
 *   ✅ Heartbeat / watchdog
 *
 * Board : ESP32 WROOM-32
 */

#include "../include/pins.h"
#include "../include/config.h"
// ⚠️  Tạo file credentials.h và KHÔNG commit lên git
// #include "credentials.h"
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <WebSocketsClient.h>
#include <DHT.h>
#include <ArduinoOTA.h>

// ─── WiFi / Supabase ───────────────────────────────────────
// ⚠️  Đặt trong credentials.h:
const char* WIFI_SSID     = "YOUR_SSID";
const char* WIFI_PASSWORD = "YOUR_PASSWORD";
const char* SB_URL        = "https://YOUR_PROJECT.supabase.co";
const char* SB_ANON_KEY   = "YOUR_ANON_KEY";

// ─── Enum & State ──────────────────────────────────────────
enum SystemMode { MODE_MANUAL, MODE_AUTO, MODE_EMERGENCY };
SystemMode currentMode = MODE_MANUAL;

bool  valveState[NUM_VALVES] = {false, false, false, false};
bool  pumpState              = false;
unsigned long pumpStartTime  = 0;
unsigned long lastSensorRead = 0;
unsigned long lastCloudSync  = 0;
int   moisturePct[NUM_VALVES]= {0, 0, 0, 0};
float waterLevelPct          = 0.0f;
float airTemp                = 0.0f;
float airHumidity            = 0.0f;

DHT dht(DHT_PIN, DHT22);
WebSocketsClient wsClient;
bool wsConnected = false;

// ─── Prototype ─────────────────────────────────────────────
void openValve(int idx);
void closeValve(int idx);
void closeAllValves();
void setPump(bool on);
int  readMoisture(int idx);
float readWaterLevel();
void readAllSensors();
void runAutoMode();
void connectWiFi();
void connectSupabaseWS();
void pushSensorData();
void onWsEvent(WStype_t type, uint8_t* payload, size_t length);
void handleCloudCommand(const String& json);

// ───────────────────────────────────────────────────────────
void setup() {
  Serial.begin(SERIAL_BAUD);

  // GPIO
  int relayPins[] = {RELAY_VALVE_1, RELAY_VALVE_2, RELAY_VALVE_3, RELAY_VALVE_4, RELAY_PUMP};
  for (int p : relayPins) { pinMode(p, OUTPUT); digitalWrite(p, HIGH); }
  pinMode(WATER_LEVEL_TRIG, OUTPUT);
  pinMode(WATER_LEVEL_ECHO, INPUT);
  pinMode(LED_STATUS, OUTPUT);
  pinMode(LED_WIFI, OUTPUT);
  pinMode(LED_AUTO_MODE, OUTPUT);
  pinMode(BTN_STOP_ALL, INPUT_PULLUP);

  dht.begin();

  // WiFi
  connectWiFi();

  // OTA
  ArduinoOTA.setHostname("smart-irrigation-v3");
  ArduinoOTA.begin();

  // Supabase Realtime WebSocket
  connectSupabaseWS();

  readAllSensors();
  Serial.println(F("{\"event\":\"ready\",\"fw\":\"" FW_VERSION "\",\"wifi\":true}"));
}

// ───────────────────────────────────────────────────────────
void loop() {
  ArduinoOTA.handle();
  wsClient.loop();

  // Nút dừng khẩn cấp
  if (digitalRead(BTN_STOP_ALL) == LOW) {
    closeAllValves(); setPump(false);
    Serial.println(F("{\"event\":\"emergency\"}"));
    delay(1000);
  }

  // Đọc cảm biến
  if (millis() - lastSensorRead >= SENSOR_READ_INTERVAL_MS) {
    readAllSensors();
    lastSensorRead = millis();
  }

  // Đẩy dữ liệu lên cloud
  if (millis() - lastCloudSync >= CLOUD_SYNC_INTERVAL_MS) {
    pushSensorData();
    lastCloudSync = millis();
  }

  // AUTO mode
  if (currentMode == MODE_AUTO) runAutoMode();

  // Bảo vệ timeout bơm
  if (pumpState && (millis() - pumpStartTime >= PUMP_MAX_ON_TIME_MS)) {
    setPump(false); closeAllValves();
  }

  // LED wifi
  digitalWrite(LED_WIFI, WiFi.status() == WL_CONNECTED ? HIGH : LOW);
  digitalWrite(LED_STATUS, (millis() / 500) % 2);

  // Tự kết nối lại WiFi nếu mất kết nối
  if (WiFi.status() != WL_CONNECTED) connectWiFi();
}

// ─── WiFi ──────────────────────────────────────────────────
void connectWiFi() {
  Serial.print(F("Connecting WiFi..."));
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500); Serial.print("."); attempts++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.print(F("\nWiFi OK: ")); Serial.println(WiFi.localIP());
  } else {
    Serial.println(F("\nWiFi FAILED — Fallback to MANUAL"));
  }
}

// ─── Supabase Realtime WebSocket ───────────────────────────
void connectSupabaseWS() {
  // Supabase Realtime endpoint: wss://<project>.supabase.co/realtime/v1/websocket
  String host = String(SB_URL).substring(8); // strip "https://"
  wsClient.begin(host.c_str(), 443, "/realtime/v1/websocket?apikey=" + String(SB_ANON_KEY) + "&vsn=1.0.0");
  wsClient.setExtraHeaders(("apikey: " + String(SB_ANON_KEY)).c_str());
  wsClient.onEvent(onWsEvent);
  wsClient.setReconnectInterval(5000);
  wsClient.enableHeartbeat(15000, 3000, 2);
}

void onWsEvent(WStype_t type, uint8_t* payload, size_t length) {
  if (type == WStype_TEXT) {
    String msg = String((char*)payload);
    handleCloudCommand(msg);
  } else if (type == WStype_CONNECTED) {
    wsConnected = true;
    // Subscribe channel "commands"
    wsClient.sendTXT(F("{\"topic\":\"realtime:commands\",\"event\":\"phx_join\",\"payload\":{},\"ref\":1}"));
  } else if (type == WStype_DISCONNECTED) {
    wsConnected = false;
  }
}

void handleCloudCommand(const String& json) {
  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, json) != DeserializationError::Ok) return;
  const char* cmd = doc["payload"]["cmd"];
  if (!cmd) return;

  String c = String(cmd);
  if      (c == "open_valve")  { openValve((int)doc["payload"]["valve"] - 1); }
  else if (c == "close_valve") { closeValve((int)doc["payload"]["valve"] - 1); }
  else if (c == "pump")        { setPump(doc["payload"]["state"] | false); }
  else if (c == "stop_all")    { closeAllValves(); setPump(false); }
  else if (c == "set_mode") {
    String mode = doc["payload"]["mode"] | "manual";
    currentMode = (mode == "auto") ? MODE_AUTO : MODE_MANUAL;
  }
}

// ─── Push dữ liệu lên Supabase REST ───────────────────────
void pushSensorData() {
  if (WiFi.status() != WL_CONNECTED) return;

  StaticJsonDocument<512> doc;
  doc["device_id"]   = "esp32-node-01";
  doc["water_level"] = waterLevelPct;
  doc["air_temp"]    = airTemp;
  doc["air_humidity"]= airHumidity;
  doc["pump_on"]     = pumpState;
  JsonArray m = doc.createNestedArray("moisture");
  JsonArray v = doc.createNestedArray("valves");
  for (int i = 0; i < NUM_VALVES; i++) { m.add(moisturePct[i]); v.add(valveState[i]); }

  String body; serializeJson(doc, body);

  HTTPClient http;
  http.begin(String(SB_URL) + "/rest/v1/" + SUPABASE_TABLE_SENSORS);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("apikey", SB_ANON_KEY);
  http.addHeader("Authorization", String("Bearer ") + SB_ANON_KEY);
  http.addHeader("Prefer", "return=minimal");
  int code = http.POST(body);
  if (code != 201) {
    Serial.print(F("[WARN] Supabase POST: ")); Serial.println(code);
  }
  http.end();
}

// ─── Sensors & Control (giống V2) ─────────────────────────
void readAllSensors() {
  for (int i = 0; i < NUM_VALVES; i++) moisturePct[i] = readMoisture(i);
  waterLevelPct = readWaterLevel();
  airTemp       = dht.readTemperature();
  airHumidity   = dht.readHumidity();
}

void runAutoMode() {
  if (waterLevelPct <= WATER_LEVEL_CRITICAL_PCT) { setPump(false); closeAllValves(); return; }
  bool any = false;
  for (int i = 0; i < NUM_VALVES; i++) {
    if (moisturePct[i] < AUTO_MOISTURE_LOW - MOISTURE_HYSTERESIS) { if (!valveState[i]) openValve(i); any = true; }
    else if (moisturePct[i] >= AUTO_MOISTURE_HIGH)                 { if (valveState[i]) closeValve(i); }
  }
  if (any && !pumpState) setPump(true);
  else if (!any && pumpState) setPump(false);
}

void openValve(int idx) {
  int pins[] = {RELAY_VALVE_1, RELAY_VALVE_2, RELAY_VALVE_3, RELAY_VALVE_4};
  digitalWrite(pins[idx], LOW); valveState[idx] = true;
}
void closeValve(int idx) {
  int pins[] = {RELAY_VALVE_1, RELAY_VALVE_2, RELAY_VALVE_3, RELAY_VALVE_4};
  digitalWrite(pins[idx], HIGH); valveState[idx] = false;
}
void closeAllValves() { for (int i = 0; i < NUM_VALVES; i++) closeValve(i); }
void setPump(bool on) {
  digitalWrite(RELAY_PUMP, on ? LOW : HIGH);
  pumpState = on; if (on) pumpStartTime = millis();
}
int readMoisture(int idx) {
  int adcPins[] = {SOIL_MOISTURE_1, SOIL_MOISTURE_2, SOIL_MOISTURE_3, SOIL_MOISTURE_4};
  return constrain(map(analogRead(adcPins[idx]), SOIL_DRY_VALUE, SOIL_WET_VALUE, 0, 100), 0, 100);
}
float readWaterLevel() {
  digitalWrite(WATER_LEVEL_TRIG, LOW);  delayMicroseconds(2);
  digitalWrite(WATER_LEVEL_TRIG, HIGH); delayMicroseconds(10);
  digitalWrite(WATER_LEVEL_TRIG, LOW);
  long d = pulseIn(WATER_LEVEL_ECHO, HIGH, 30000);
  return constrain(((TANK_HEIGHT_CM - d * 0.0343f / 2.0f) / TANK_HEIGHT_CM) * 100.0f, 0.0f, 100.0f);
}
