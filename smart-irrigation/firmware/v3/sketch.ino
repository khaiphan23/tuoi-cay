// ===== SMART IRRIGATION V3 =====
// firmware/v3/sketch.ino
// Thêm: WiFi + Supabase polling + sync state

#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "../include/pins.h"
#include "../include/config.h"

// ----- Trạng thái hệ thống -----
bool pumpOn   = false;
bool valve1On = false;
bool valve2On = false;
bool autoMode = false;
bool lowWater = false;

// ----- Cảm biến -----
int soilRaw     = 0;
int soilPercent = 0;

// ----- WiFi -----
void connectWiFi() {
  Serial.print("Ket noi WiFi: ");
  Serial.println(WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 20) {
    delay(500);
    Serial.print(".");
    retry++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.print("[OK] WiFi: ");
    Serial.println(WiFi.localIP());
    digitalWrite(LED_STATUS, HIGH);
  } else {
    Serial.println();
    Serial.println("[LOI] Khong ket noi duoc WiFi");
    digitalWrite(LED_ERROR, HIGH);
  }
}

// ----- Supabase HTTP -----
String supabaseGet(String endpoint) {
  if (WiFi.status() != WL_CONNECTED) return "";

  HTTPClient http;
  String url = String(SUPABASE_URL) + endpoint;
  http.begin(url);
  http.addHeader("apikey", SUPABASE_KEY);
  http.addHeader("Authorization", String("Bearer ") + SUPABASE_KEY);
  http.addHeader("Content-Type", "application/json");

  int code = http.GET();
  String body = "";
  if (code == 200) body = http.getString();
  http.end();
  return body;
}

bool supabasePatch(String endpoint, String payload) {
  if (WiFi.status() != WL_CONNECTED) return false;

  HTTPClient http;
  String url = String(SUPABASE_URL) + endpoint;
  http.begin(url);
  http.addHeader("apikey", SUPABASE_KEY);
  http.addHeader("Authorization", String("Bearer ") + SUPABASE_KEY);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Prefer", "return=minimal");

  int code = http.PATCH(payload);
  http.end();
  return (code == 204);
}

bool supabasePost(String endpoint, String payload) {
  if (WiFi.status() != WL_CONNECTED) return false;

  HTTPClient http;
  String url = String(SUPABASE_URL) + endpoint;
  http.begin(url);
  http.addHeader("apikey", SUPABASE_KEY);
  http.addHeader("Authorization", String("Bearer ") + SUPABASE_KEY);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("Prefer", "return=minimal");

  int code = http.POST(payload);
  http.end();
  return (code == 201);
}

// ----- Sync state lên Supabase -----
void syncState() {
  String payload = "{";
  payload += "\"pump_on\":"   + String(pumpOn    ? "true" : "false") + ",";
  payload += "\"valve1_on\":" + String(valve1On  ? "true" : "false") + ",";
  payload += "\"valve2_on\":" + String(valve2On  ? "true" : "false") + ",";
  payload += "\"auto_mode\":" + String(autoMode  ? "true" : "false") + ",";
  payload += "\"low_water\":" + String(lowWater  ? "true" : "false") + ",";
  payload += "\"soil_pct\":"  + String(soilPercent) + ",";
  payload += "\"updated_at\":\"now()\"";
  payload += "}";

  String endpoint = "/rest/v1/system_state?device_id=eq." + String(DEVICE_ID);
  supabasePatch(endpoint, payload);
}

// ----- Ghi log -----
void logAction(String action) {
  String payload = "{";
  payload += "\"device_id\":\"" + String(DEVICE_ID) + "\",";
  payload += "\"action\":\"" + action + "\",";
  payload += "\"soil_pct\":" + String(soilPercent);
  payload += "}";
  supabasePost("/rest/v1/irrigation_logs", payload);
}

// ----- Polling lệnh từ Supabase -----
void pollCommands() {
  String endpoint = "/rest/v1/commands?device_id=eq."
                  + String(DEVICE_ID)
                  + "&executed=eq.false&order=created_at.asc&limit=1";

  String body = supabaseGet(endpoint);
  if (body == "" || body == "[]") return;

  // Parse JSON
  StaticJsonDocument<512> doc;
  DeserializationError err = deserializeJson(doc, body);
  if (err || doc.size() == 0) return;

  String cmdId  = doc[0]["id"].as<String>();
  String cmd    = doc[0]["command"].as<String>();
  cmd.toUpperCase();

  Serial.print("[CMD] Nhan lenh: ");
  Serial.println(cmd);

  // Đánh dấu executed = true trước
  String markDone = "{\"executed\":true}";
  supabasePatch("/rest/v1/commands?id=eq." + cmdId, markDone);

  // Thực thi lệnh
  processCommand(cmd);

  // Sync state sau khi thực thi
  syncState();
}

// ========== Hardware Init ==========
void initHardware() {
  pinMode(RELAY_PIN,  OUTPUT);
  pinMode(LED_VALVE1, OUTPUT);
  pinMode(LED_VALVE2, OUTPUT);
  pinMode(LED_PUMP,   OUTPUT);
  pinMode(LED_STATUS, OUTPUT);
  pinMode(LED_ERROR,  OUTPUT);
  pinMode(FLOAT_PIN,  INPUT_PULLUP);

  digitalWrite(RELAY_PIN,  LOW);
  digitalWrite(LED_VALVE1, LOW);
  digitalWrite(LED_VALVE2, LOW);
  digitalWrite(LED_PUMP,   LOW);
  digitalWrite(LED_ERROR,  LOW);
  digitalWrite(LED_STATUS, LOW);
}

// ========== Pump ==========
void startPump() {
  pumpOn = true;
  digitalWrite(RELAY_PIN, HIGH);
  digitalWrite(LED_PUMP,  HIGH);
}

void stopPump() {
  pumpOn = false;
  digitalWrite(RELAY_PIN, LOW);
  digitalWrite(LED_PUMP,  LOW);
}

// ========== Valve ==========
void openValve1() {
  valve1On = true;
  digitalWrite(LED_VALVE1, HIGH);
}

void closeValve1() {
  valve1On = false;
  digitalWrite(LED_VALVE1, LOW);
}

void openValve2() {
  valve2On = true;
  digitalWrite(LED_VALVE2, HIGH);
}

void closeValve2() {
  valve2On = false;
  digitalWrite(LED_VALVE2, LOW);
}

bool anyValveOn() {
  return valve1On || valve2On;
}

// ========== Mode ==========
void setModeAuto()   { autoMode = true;  }
void setModeManual() { autoMode = false; }

// ========== Safety ==========
void emergencyStop() {
  stopPump();
  closeValve1();
  closeValve2();
  digitalWrite(LED_ERROR, HIGH);
  logAction("EMERGENCY_STOP");
}

void checkSafety() {
  static bool lastRaw     = false;
  static bool stableState = false;
  static unsigned long lastDebounce = 0;

  bool raw = (digitalRead(FLOAT_PIN) == LOW);

  if (raw != lastRaw) {
    lastDebounce = millis();
    lastRaw = raw;
  }

  if (millis() - lastDebounce >= DEBOUNCE_MS) {
    if (stableState != raw) {
      stableState = raw;
      lowWater = stableState;

      if (stableState) {
        emergencyStop();
        Serial.println("!!! CAN NUOC !!!");
      } else {
        digitalWrite(LED_ERROR, LOW);
        Serial.println("[OK] Da co nuoc");
      }
      syncState();
    }
  }
}

// ========== Sensor ==========
void readSoil() {
  soilRaw     = analogRead(SOIL_PIN);
  soilPercent = constrain(map(soilRaw, 0, 4095, 0, 100), 0, 100);
}

// ========== Command ==========
void processCommand(String cmd) {
  if (lowWater && cmd != "STATUS") {
    Serial.println("LOI: Can nuoc");
    return;
  }

  if (cmd == "AUTO")   { setModeAuto();   Serial.println("[OK] AUTO");   return; }
  if (cmd == "MANUAL") { setModeManual(); Serial.println("[OK] MANUAL"); return; }

  bool isManualCmd = (cmd == "ON"   || cmd == "OFF"   ||
                      cmd == "V1ON" || cmd == "V1OFF"  ||
                      cmd == "V2ON" || cmd == "V2OFF"  ||
                      cmd == "PON"  || cmd == "POFF");

  if (autoMode && isManualCmd) {
    Serial.println("LOI: Dang o AUTO"); return;
  }

  if (cmd == "ON") {
    if (pumpOn || valve1On) { Serial.println("LOI: Da chay"); return; }
    openValve1(); delay(200); startPump();
    Serial.println("[OK] Dang tuoi");
    logAction("ON");
  }
  else if (cmd == "OFF") {
    if (!pumpOn && !valve1On && !valve2On) { Serial.println("LOI: Da dung"); return; }
    stopPump(); delay(200); closeValve1(); closeValve2();
    Serial.println("[OK] Da dung");
    logAction("OFF");
  }
  else if (cmd == "V1ON")  { if (valve1On) return; openValve1();  Serial.println("[OK] V1 ON");  logAction("V1ON"); }
  else if (cmd == "V1OFF") {
    if (!valve1On) return;
    if (pumpOn && !valve2On) { Serial.println("LOI: Tat bom truoc"); return; }
    closeValve1(); Serial.println("[OK] V1 OFF"); logAction("V1OFF");
  }
  else if (cmd == "V2ON")  { if (valve2On) return; openValve2();  Serial.println("[OK] V2 ON");  logAction("V2ON"); }
  else if (cmd == "V2OFF") {
    if (!valve2On) return;
    if (pumpOn && !valve1On) { Serial.println("LOI: Tat bom truoc"); return; }
    closeValve2(); Serial.println("[OK] V2 OFF"); logAction("V2OFF");
  }
  else if (cmd == "PON")  {
    if (pumpOn) return;
    if (!anyValveOn()) { Serial.println("LOI: Chua mo van"); return; }
    startPump(); Serial.println("[OK] Bom ON"); logAction("PON");
  }
  else if (cmd == "POFF") {
    if (!pumpOn) return;
    stopPump(); Serial.println("[OK] Bom OFF"); logAction("POFF");
  }
}

// ========== Setup ==========
void setup() {
  Serial.begin(115200);
  Serial.setTimeout(20);
  initHardware();

  Serial.println();
  Serial.println("===== SMART IRRIGATION V3 =====");

  connectWiFi();

  // Báo online
  String online = "{\"online\":true,\"updated_at\":\"now()\"}";
  supabasePatch("/rest/v1/devices?id=eq." + String(DEVICE_ID), online);

  Serial.println("Go HELP de xem lenh");
  Serial.println("================================");
}

// ========== Loop ==========
void loop() {
  // Đọc cảm biến mỗi 1 giây
  static unsigned long lastSensor = 0;
  if (millis() - lastSensor >= SENSOR_INTERVAL) {
    lastSensor = millis();
    readSoil();
    Serial.print("Do am: ");
    Serial.print(soilPercent);
    Serial.println("%");
  }

  // Kiểm tra an toàn
  checkSafety();

  // Polling lệnh từ Supabase mỗi 2 giây
  static unsigned long lastPoll = 0;
  if (millis() - lastPoll >= POLL_INTERVAL) {
    lastPoll = millis();
    pollCommands();
  }

  // Sync state mỗi 10 giây
  static unsigned long lastSync = 0;
  if (millis() - lastSync >= 10000) {
    lastSync = millis();
    syncState();
  }

  // Vẫn nhận lệnh Serial để debug
  if (Serial.available()) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    cmd.toUpperCase();
    processCommand(cmd);
    syncState();
  }
}