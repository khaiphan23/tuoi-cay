/**
 * config.h — Cấu hình hệ thống Smart Irrigation
 *
 * Ngưỡng AUTO, timeout, phiên bản, thông số kết nối
 * Cập nhật lần cuối: 2026-06-28
 */

#pragma once

// ─────────────────────────────────────────────
//  PHIÊN BẢN FIRMWARE
// ─────────────────────────────────────────────
#define FW_VERSION          "2.0.0"
#define FW_BUILD_DATE       "2026-06-28"
#define SERIAL_BAUD         115200

// ─────────────────────────────────────────────
//  NGƯỠNG AUTO (% độ ẩm đất)
// ─────────────────────────────────────────────
#define AUTO_MOISTURE_LOW   30    // Dưới ngưỡng → bật van/bơm
#define AUTO_MOISTURE_HIGH  70    // Đạt ngưỡng  → tắt van/bơm
#define MOISTURE_HYSTERESIS 5     // Biên trễ tránh dao động

// ─────────────────────────────────────────────
//  TIMEOUT & THỜI GIAN (milliseconds)
// ─────────────────────────────────────────────
#define PUMP_MAX_ON_TIME_MS       (30UL * 60 * 1000)  // 30 phút — bảo vệ bơm
#define VALVE_OPEN_TIMEOUT_MS     (45UL * 60 * 1000)  // 45 phút — tối đa 1 van mở
#define SENSOR_READ_INTERVAL_MS   5000                // Đọc cảm biến mỗi 5 giây
#define CLOUD_SYNC_INTERVAL_MS    10000               // Đồng bộ cloud mỗi 10 giây
#define DEBOUNCE_DELAY_MS         50                  // Debounce nút bấm

// ─────────────────────────────────────────────
//  MỨC NƯỚC BỂ CHỨA
// ─────────────────────────────────────────────
#define TANK_HEIGHT_CM            100   // Chiều cao bể tính từ cảm biến (cm)
#define WATER_LEVEL_LOW_PCT       20    // % mực nước thấp → cảnh báo
#define WATER_LEVEL_CRITICAL_PCT  10    // % mực nước nguy hiểm → khóa bơm

// ─────────────────────────────────────────────
//  CẢM BIẾN ĐỘ ẨM — Hiệu chỉnh ADC (12-bit, 0–4095)
// ─────────────────────────────────────────────
#define SOIL_DRY_VALUE    3200    // Giá trị ADC khi đất khô hoàn toàn
#define SOIL_WET_VALUE    800     // Giá trị ADC khi đất bão hòa nước

// ─────────────────────────────────────────────
//  WIFI (V3+) — Đặt trong credentials.h riêng, không commit lên git
// ─────────────────────────────────────────────
// #define WIFI_SSID        "YourSSID"
// #define WIFI_PASSWORD    "YourPassword"

// ─────────────────────────────────────────────
//  SUPABASE (V3+)
// ─────────────────────────────────────────────
// #define SUPABASE_URL     "https://xxxx.supabase.co"
// #define SUPABASE_ANON_KEY "eyJ..."
#define SUPABASE_TABLE_SENSORS    "sensor_logs"
#define SUPABASE_TABLE_COMMANDS   "commands"
#define SUPABASE_TABLE_VALVES     "valve_status"

// ─────────────────────────────────────────────
//  SỐ LƯỢNG VAN
// ─────────────────────────────────────────────
#define NUM_VALVES        4
#define NUM_ZONES         4
