/**
 * pins.h — Định nghĩa tất cả chân GPIO cho Smart Irrigation System
 * 
 * Board target : ESP32 (WROOM-32 / WROOM-32U)
 * Cập nhật lần cuối: 2026-06-28
 */

#pragma once

// ─────────────────────────────────────────────
//  RELAY — Van tưới (Active LOW)
// ─────────────────────────────────────────────
#define RELAY_VALVE_1     25   // Van khu 1
#define RELAY_VALVE_2     26   // Van khu 2
#define RELAY_VALVE_3     27   // Van khu 3
#define RELAY_VALVE_4     14   // Van khu 4
#define RELAY_PUMP        13   // Relay bơm chính

// ─────────────────────────────────────────────
//  SENSOR — Cảm biến
// ─────────────────────────────────────────────
#define SOIL_MOISTURE_1   34   // Cảm biến độ ẩm đất khu 1 (ADC1_CH6)
#define SOIL_MOISTURE_2   35   // Cảm biến độ ẩm đất khu 2 (ADC1_CH7)
#define SOIL_MOISTURE_3   32   // Cảm biến độ ẩm đất khu 3 (ADC1_CH4)
#define SOIL_MOISTURE_4   33   // Cảm biến độ ẩm đất khu 4 (ADC1_CH5)

#define WATER_LEVEL_TRIG  5    // Ultrasonic HC-SR04 Trig
#define WATER_LEVEL_ECHO  18   // Ultrasonic HC-SR04 Echo

#define DHT_PIN           4    // Cảm biến DHT22 (nhiệt độ / độ ẩm không khí)
#define FLOW_SENSOR_PIN   19   // Cảm biến lưu lượng nước (pulse)

// ─────────────────────────────────────────────
//  BUTTON — Nút bấm vật lý
// ─────────────────────────────────────────────
#define BTN_MANUAL_MODE   0    // BOOT button — chuyển chế độ thủ công
#define BTN_STOP_ALL      15   // Dừng khẩn cấp tất cả

// ─────────────────────────────────────────────
//  LED — Đèn trạng thái
// ─────────────────────────────────────────────
#define LED_STATUS        2    // LED xanh onboard
#define LED_AUTO_MODE     21   // LED chỉ chế độ AUTO
#define LED_WIFI          22   // LED trạng thái WiFi (V3+)

// ─────────────────────────────────────────────
//  I2C — LCD / OLED (optional)
// ─────────────────────────────────────────────
#define I2C_SDA           21
#define I2C_SCL           22

// ─────────────────────────────────────────────
//  UART — Module 4G A7670C (V4)
// ─────────────────────────────────────────────
#define A7670C_TX         17   // ESP32 TX → A7670C RX
#define A7670C_RX         16   // ESP32 RX → A7670C TX
#define A7670C_PWRKEY     23   // Power key A7670C
