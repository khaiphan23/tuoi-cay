/**
 * Smart Irrigation System — Firmware V1 (FROZEN ✅)
 * 
 * Chức năng:
 *   - Điều khiển thủ công 4 van + 1 bơm qua Serial Monitor
 *   - Đọc 4 cảm biến độ ẩm đất (ADC)
 *   - Đọc mực nước bể (HC-SR04)
 *   - Bảo vệ timeout bơm
 * 
 * ⚠️  File này đã ĐÓNG BĂNG — Không chỉnh sửa
 * Board : ESP32 WROOM-32
 * IDE   : Arduino IDE 2.x / PlatformIO
 */

#include "../include/pins.h"
#include "../include/config.h"

// ─── Biến trạng thái ───────────────────────────────────────
bool valveState[NUM_VALVES] = {false, false, false, false};
bool pumpState = false;
unsigned long pumpStartTime = 0;

// ─── Prototype ─────────────────────────────────────────────
void openValve(int idx);
void closeValve(int idx);
void closeAllValves();
void setPump(bool on);
int  readMoisture(int idx);
float readWaterLevel();
void printStatus();
void handleSerial();

// ───────────────────────────────────────────────────────────
void setup() {
  Serial.begin(SERIAL_BAUD);
  Serial.println(F("=== Smart Irrigation V1 ==="));
  Serial.print(F("Firmware: ")); Serial.println(FW_VERSION);

  // Relay — mặc định OFF (Active LOW → HIGH = tắt)
  int relayPins[] = {RELAY_VALVE_1, RELAY_VALVE_2, RELAY_VALVE_3, RELAY_VALVE_4, RELAY_PUMP};
  for (int p : relayPins) {
    pinMode(p, OUTPUT);
    digitalWrite(p, HIGH);
  }

  // Cảm biến
  pinMode(WATER_LEVEL_TRIG, OUTPUT);
  pinMode(WATER_LEVEL_ECHO, INPUT);
  pinMode(BTN_MANUAL_MODE, INPUT_PULLUP);
  pinMode(BTN_STOP_ALL, INPUT_PULLUP);
  pinMode(LED_STATUS, OUTPUT);

  Serial.println(F("Sẵn sàng. Lệnh: V1/V2/V3/V4 (bật van), P (bơm), X (tắt tất cả), S (trạng thái)"));
}

// ───────────────────────────────────────────────────────────
void loop() {
  // Xử lý lệnh Serial
  if (Serial.available()) handleSerial();

  // Bảo vệ timeout bơm
  if (pumpState && (millis() - pumpStartTime >= PUMP_MAX_ON_TIME_MS)) {
    Serial.println(F("[WARN] Bơm quá thời gian — Tự động tắt!"));
    setPump(false);
    closeAllValves();
  }

  // Nút dừng khẩn cấp
  if (digitalRead(BTN_STOP_ALL) == LOW) {
    Serial.println(F("[EMERGENCY] Nút dừng được nhấn!"));
    closeAllValves();
    setPump(false);
    delay(500);
  }

  // Nhấp nháy LED trạng thái
  digitalWrite(LED_STATUS, (millis() / 500) % 2);
  delay(50);
}

// ─── Hàm điều khiển ────────────────────────────────────────
void openValve(int idx) {
  if (idx < 0 || idx >= NUM_VALVES) return;
  int pins[] = {RELAY_VALVE_1, RELAY_VALVE_2, RELAY_VALVE_3, RELAY_VALVE_4};
  digitalWrite(pins[idx], LOW);   // Active LOW
  valveState[idx] = true;
  Serial.print(F("[OK] Van ")); Serial.print(idx + 1); Serial.println(F(" MỞ"));
}

void closeValve(int idx) {
  if (idx < 0 || idx >= NUM_VALVES) return;
  int pins[] = {RELAY_VALVE_1, RELAY_VALVE_2, RELAY_VALVE_3, RELAY_VALVE_4};
  digitalWrite(pins[idx], HIGH);
  valveState[idx] = false;
  Serial.print(F("[OK] Van ")); Serial.print(idx + 1); Serial.println(F(" ĐÓNG"));
}

void closeAllValves() {
  for (int i = 0; i < NUM_VALVES; i++) closeValve(i);
}

void setPump(bool on) {
  digitalWrite(RELAY_PUMP, on ? LOW : HIGH);
  pumpState = on;
  if (on) pumpStartTime = millis();
  Serial.print(F("[OK] Bơm ")); Serial.println(on ? F("BẬT") : F("TẮT"));
}

// ─── Đọc cảm biến ──────────────────────────────────────────
int readMoisture(int idx) {
  int adcPins[] = {SOIL_MOISTURE_1, SOIL_MOISTURE_2, SOIL_MOISTURE_3, SOIL_MOISTURE_4};
  int raw = analogRead(adcPins[idx]);
  // Map: SOIL_DRY_VALUE → 0%, SOIL_WET_VALUE → 100%
  int pct = map(raw, SOIL_DRY_VALUE, SOIL_WET_VALUE, 0, 100);
  return constrain(pct, 0, 100);
}

float readWaterLevel() {
  digitalWrite(WATER_LEVEL_TRIG, LOW);  delayMicroseconds(2);
  digitalWrite(WATER_LEVEL_TRIG, HIGH); delayMicroseconds(10);
  digitalWrite(WATER_LEVEL_TRIG, LOW);
  long duration = pulseIn(WATER_LEVEL_ECHO, HIGH, 30000);
  float distCm = duration * 0.0343f / 2.0f;
  float levelPct = ((TANK_HEIGHT_CM - distCm) / TANK_HEIGHT_CM) * 100.0f;
  return constrain(levelPct, 0.0f, 100.0f);
}

// ─── In trạng thái ─────────────────────────────────────────
void printStatus() {
  Serial.println(F("\n─── Trạng thái hệ thống ───"));
  for (int i = 0; i < NUM_VALVES; i++) {
    Serial.print(F("  Van ")); Serial.print(i + 1);
    Serial.print(F(": ")); Serial.print(valveState[i] ? F("MỞ") : F("ĐÓNG"));
    Serial.print(F(" | Độ ẩm: ")); Serial.print(readMoisture(i)); Serial.println(F("%"));
  }
  Serial.print(F("  Bơm: ")); Serial.println(pumpState ? F("BẬT") : F("TẮT"));
  Serial.print(F("  Mực nước: ")); Serial.print(readWaterLevel(), 1); Serial.println(F("%"));
  Serial.println(F("───────────────────────────\n"));
}

// ─── Xử lý lệnh Serial ─────────────────────────────────────
void handleSerial() {
  String cmd = Serial.readStringUntil('\n');
  cmd.trim(); cmd.toUpperCase();

  if      (cmd == "V1") openValve(0);
  else if (cmd == "V2") openValve(1);
  else if (cmd == "V3") openValve(2);
  else if (cmd == "V4") openValve(3);
  else if (cmd == "C1") closeValve(0);
  else if (cmd == "C2") closeValve(1);
  else if (cmd == "C3") closeValve(2);
  else if (cmd == "C4") closeValve(3);
  else if (cmd == "P")  setPump(!pumpState);
  else if (cmd == "X")  { closeAllValves(); setPump(false); }
  else if (cmd == "S")  printStatus();
  else { Serial.print(F("[ERR] Lệnh không hợp lệ: ")); Serial.println(cmd); }
}
