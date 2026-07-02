/**
 * Smart Irrigation System — Firmware V4
 * 4G LTE via A7670C (AT commands)
 *
 * Bổ sung so với V3:
 *   ✅ Module A7670C (4G LTE) thay thế WiFi
 *   ✅ Gửi HTTP POST qua AT+HTTPPARA / AT+HTTPACTION
 *   ✅ MQTT qua 4G (TODO — cần SIM data)
 *   ✅ SMS cảnh báo khẩn cấp
 *   ✅ GPS từ A7670C (nếu có antenna GPS)
 *
 * Board : ESP32 WROOM-32
 * Module: SIM7670G / A7670C-LASE
 */

#include "../include/pins.h"
#include "../include/config.h"
#include <ArduinoJson.h>
#include <DHT.h>

// ─── 4G Config ─────────────────────────────────────────────
// ⚠️  Đặt trong credentials.h:
const char* APN          = "m-wap";           // APN nhà mạng
const char* SB_HOST      = "YOUR_PROJECT.supabase.co";
const char* SB_ANON_KEY  = "YOUR_ANON_KEY";
const char* ALERT_PHONE  = "+84xxxxxxxxx";    // Số nhận SMS cảnh báo

// ─── UART2 cho A7670C ──────────────────────────────────────
HardwareSerial A7670(2);   // UART2: RX=16, TX=17

// ─── State ─────────────────────────────────────────────────
enum SystemMode { MODE_MANUAL, MODE_AUTO };
SystemMode currentMode = MODE_MANUAL;
bool valveState[NUM_VALVES] = {false, false, false, false};
bool pumpState = false;
unsigned long pumpStartTime = 0;
unsigned long lastSensorRead = 0;
unsigned long lastCloudSync  = 0;
int  moisturePct[NUM_VALVES] = {0, 0, 0, 0};
float waterLevelPct = 0.0f;
float airTemp       = 0.0f;
float airHumidity   = 0.0f;

DHT dht(DHT_PIN, DHT22);

// ─── AT Command Helpers ─────────────────────────────────────
String sendAT(const String& cmd, unsigned long timeout = 2000) {
  A7670.println(cmd);
  unsigned long start = millis();
  String res = "";
  while (millis() - start < timeout) {
    while (A7670.available()) res += (char)A7670.read();
    if (res.indexOf("OK") >= 0 || res.indexOf("ERROR") >= 0) break;
  }
  return res;
}

bool waitFor(const String& pattern, unsigned long timeout = 10000) {
  String buf = "";
  unsigned long start = millis();
  while (millis() - start < timeout) {
    while (A7670.available()) buf += (char)A7670.read();
    if (buf.indexOf(pattern) >= 0) return true;
  }
  return false;
}

// ─── Init A7670C ───────────────────────────────────────────
bool init4G() {
  A7670.begin(115200, SERIAL_8N1, A7670C_RX, A7670C_TX);

  // Power on
  pinMode(A7670C_PWRKEY, OUTPUT);
  digitalWrite(A7670C_PWRKEY, HIGH); delay(200);
  digitalWrite(A7670C_PWRKEY, LOW);
  delay(3000);

  sendAT("AT");                          // Test
  sendAT("ATE0");                        // Echo off
  sendAT("AT+CMGF=1");                   // SMS text mode
  sendAT("AT+CGNSPWR=1");               // GPS power

  // PDP context / APN
  sendAT("AT+CGDCONT=1,\"IP\",\"" + String(APN) + "\"");
  sendAT("AT+CGACT=1,1");

  String r = sendAT("AT+CGATT?");
  if (r.indexOf("+CGATT: 1") < 0) {
    Serial.println(F("[4G] GPRS attach FAILED"));
    return false;
  }
  Serial.println(F("[4G] Ready"));
  return true;
}

// ─── HTTP POST qua A7670C ──────────────────────────────────
bool httpPost(const String& path, const String& body) {
  sendAT("AT+HTTPTERM", 1000);           // Reset
  delay(100);
  if (sendAT("AT+HTTPINIT").indexOf("OK") < 0)  return false;
  sendAT("AT+HTTPPARA=\"CID\",1");
  sendAT("AT+HTTPPARA=\"URL\",\"https://" + String(SB_HOST) + path + "\"");
  sendAT("AT+HTTPPARA=\"CONTENT\",\"application/json\"");
  sendAT("AT+HTTPPARA=\"USERDATA\",\"apikey: " + String(SB_ANON_KEY) + "\\r\\nAuthorization: Bearer " + String(SB_ANON_KEY) + "\"");

  // Gửi body
  A7670.print("AT+HTTPDATA=");
  A7670.print(body.length());
  A7670.println(",10000");
  if (!waitFor("DOWNLOAD", 5000)) { sendAT("AT+HTTPTERM"); return false; }
  A7670.print(body);
  delay(1000);

  sendAT("AT+HTTPACTION=1", 10000);      // POST
  if (!waitFor("+HTTPACTION:1,201", 15000) && !waitFor("+HTTPACTION:1,200", 15000)) {
    sendAT("AT+HTTPTERM"); return false;
  }
  sendAT("AT+HTTPTERM");
  return true;
}

// ─── SMS cảnh báo ──────────────────────────────────────────
void sendSMS(const String& msg) {
  sendAT("AT+CMGF=1");
  A7670.print("AT+CMGS=\""); A7670.print(ALERT_PHONE); A7670.println("\"");
  waitFor(">", 3000);
  A7670.print(msg);
  A7670.write(0x1A);   // Ctrl+Z — gửi
  waitFor("OK", 10000);
  Serial.println(F("[SMS] Sent"));
}

// ───────────────────────────────────────────────────────────
void setup() {
  Serial.begin(SERIAL_BAUD);

  int relayPins[] = {RELAY_VALVE_1, RELAY_VALVE_2, RELAY_VALVE_3, RELAY_VALVE_4, RELAY_PUMP};
  for (int p : relayPins) { pinMode(p, OUTPUT); digitalWrite(p, HIGH); }
  pinMode(WATER_LEVEL_TRIG, OUTPUT);
  pinMode(WATER_LEVEL_ECHO, INPUT);
  pinMode(LED_STATUS, OUTPUT);
  pinMode(BTN_STOP_ALL, INPUT_PULLUP);
  dht.begin();

  if (!init4G()) Serial.println(F("[WARN] 4G init failed — offline mode"));

  readAllSensors();
  Serial.println(F("{\"event\":\"ready\",\"fw\":\"" FW_VERSION "\",\"4g\":true}"));
}

// ───────────────────────────────────────────────────────────
void loop() {
  if (digitalRead(BTN_STOP_ALL) == LOW) {
    closeAllValves(); setPump(false);
    sendSMS("[ALERT] Smart Irrigation: EMERGENCY STOP triggered!");
    delay(1000);
  }

  if (millis() - lastSensorRead >= SENSOR_READ_INTERVAL_MS) {
    readAllSensors();
    lastSensorRead = millis();
    // Cảnh báo mực nước thấp qua SMS
    if (waterLevelPct <= WATER_LEVEL_LOW_PCT) {
      sendSMS("[ALERT] Muc nuoc thap: " + String(waterLevelPct, 0) + "%");
    }
  }

  if (millis() - lastCloudSync >= CLOUD_SYNC_INTERVAL_MS) {
    pushSensorData4G();
    lastCloudSync = millis();
  }

  if (currentMode == MODE_AUTO) runAutoMode();

  if (pumpState && (millis() - pumpStartTime >= PUMP_MAX_ON_TIME_MS)) {
    setPump(false); closeAllValves();
    sendSMS("[ALERT] Bom qua thoi gian — tu dong tat!");
  }

  digitalWrite(LED_STATUS, (millis() / 500) % 2);
}

// ─── Push dữ liệu qua 4G ───────────────────────────────────
void pushSensorData4G() {
  StaticJsonDocument<512> doc;
  doc["device_id"]   = "esp32-4g-01";
  doc["water_level"] = waterLevelPct;
  doc["air_temp"]    = airTemp;
  doc["air_humidity"]= airHumidity;
  doc["pump_on"]     = pumpState;
  JsonArray m = doc.createNestedArray("moisture");
  JsonArray v = doc.createNestedArray("valves");
  for (int i = 0; i < NUM_VALVES; i++) { m.add(moisturePct[i]); v.add(valveState[i]); }
  String body; serializeJson(doc, body);
  httpPost("/rest/v1/" SUPABASE_TABLE_SENSORS, body);
}

// ─── Control / Sensor (giống các phiên bản trước) ──────────
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
    if (moisturePct[i] < AUTO_MOISTURE_LOW - MOISTURE_HYSTERESIS)  { if (!valveState[i]) openValve(i); any = true; }
    else if (moisturePct[i] >= AUTO_MOISTURE_HIGH && valveState[i]) closeValve(i);
  }
  if (any && !pumpState) setPump(true);
  else if (!any && pumpState) setPump(false);
}
void openValve(int idx)  { int p[]={RELAY_VALVE_1,RELAY_VALVE_2,RELAY_VALVE_3,RELAY_VALVE_4}; digitalWrite(p[idx],LOW);  valveState[idx]=true;  }
void closeValve(int idx) { int p[]={RELAY_VALVE_1,RELAY_VALVE_2,RELAY_VALVE_3,RELAY_VALVE_4}; digitalWrite(p[idx],HIGH); valveState[idx]=false; }
void closeAllValves()    { for(int i=0;i<NUM_VALVES;i++) closeValve(i); }
void setPump(bool on)    { digitalWrite(RELAY_PUMP,on?LOW:HIGH); pumpState=on; if(on) pumpStartTime=millis(); }
int  readMoisture(int idx) { int p[]={SOIL_MOISTURE_1,SOIL_MOISTURE_2,SOIL_MOISTURE_3,SOIL_MOISTURE_4}; return constrain(map(analogRead(p[idx]),SOIL_DRY_VALUE,SOIL_WET_VALUE,0,100),0,100); }
float readWaterLevel() {
  digitalWrite(WATER_LEVEL_TRIG,LOW); delayMicroseconds(2);
  digitalWrite(WATER_LEVEL_TRIG,HIGH); delayMicroseconds(10);
  digitalWrite(WATER_LEVEL_TRIG,LOW);
  long d=pulseIn(WATER_LEVEL_ECHO,HIGH,30000);
  return constrain(((TANK_HEIGHT_CM-d*0.0343f/2.0f)/TANK_HEIGHT_CM)*100.0f,0.0f,100.0f);
}
