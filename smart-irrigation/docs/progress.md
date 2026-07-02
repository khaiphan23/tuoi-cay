# Progress — Tiến độ phát triển Smart Irrigation System

## Tổng quan dự án

| Hạng mục        | Trạng thái      | Ghi chú                              |
|-----------------|-----------------|--------------------------------------|
| Phần cứng       | ✅ Sẵn sàng     | ESP32 + Relay + Cảm biến             |
| Firmware V1     | ✅ Đóng băng    | Serial manual control                |
| Firmware V2     | ⏳ Đang phát triển | AUTO mode + JSON protocol         |
| Firmware V3     | 📋 Kế hoạch     | WiFi + Supabase                      |
| Firmware V4     | 📋 Kế hoạch     | 4G A7670C                            |
| Supabase schema | 📋 Viết sau V2  | Đang chờ V2 ổn định                  |
| Flutter App     | 🔨 Scaffolding  | Cấu trúc sẵn, cần kết nối Supabase  |

---

## V1 — Đã hoàn thành ✅ `2026-06-xx`

### Tính năng
- [x] Điều khiển thủ công 4 van qua Serial (V1/V2/V3/V4/C1-C4)
- [x] Bật/tắt bơm (lệnh `P`)
- [x] Đọc 4 cảm biến độ ẩm đất (ADC 12-bit → %)
- [x] Đọc mực nước bể (HC-SR04)
- [x] Bảo vệ timeout bơm 30 phút
- [x] Nút dừng khẩn cấp phần cứng
- [x] In trạng thái (lệnh `S`)
- [x] LED nhấp nháy trạng thái
- [x] Sơ đồ Wokwi `diagram.json`

### Đã test
- [x] Simulation Wokwi
- [ ] Hardware thực tế

---

## V2 — Đang phát triển ⏳

### Tính năng đã xong
- [x] State machine: MANUAL / AUTO / EMERGENCY
- [x] Giao thức lệnh JSON qua Serial
- [x] Chế độ AUTO (ngưỡng ± hysteresis)
- [x] DHT22 — đọc nhiệt độ & độ ẩm không khí
- [x] Chuyển chế độ bằng nút vật lý
- [x] Gửi trạng thái JSON định kỳ

### TODO V2
- [ ] Lịch tưới định kỳ (RTC DS3231)
- [ ] Lưu cài đặt ngưỡng vào EEPROM
- [ ] Test hardware thực tế
- [ ] Kiểm tra hysteresis không dao động

---

## V3 — Kế hoạch 📋

### Yêu cầu
- [ ] WiFi connect + auto-reconnect
- [ ] Push sensor data lên Supabase REST
- [ ] Lắng nghe lệnh qua Supabase Realtime (WebSocket)
- [ ] OTA firmware update qua WiFi
- [ ] Heartbeat / watchdog
- [ ] **Điều kiện bắt đầu**: V2 ổn định trên hardware

---

## V4 — Kế hoạch 📋

### Yêu cầu
- [ ] Module A7670C init (AT commands)
- [ ] HTTP POST qua 4G (AT+HTTPACTION)
- [ ] SMS cảnh báo (mực nước thấp, bơm timeout)
- [ ] GPS tracking (AT+CGNSINF)
- [ ] **Điều kiện bắt đầu**: V3 đã test thành công

---

## Flutter App — Scaffolding 🔨

### Đã tạo cấu trúc
- [x] `main.dart` — Supabase init + GetX DI
- [x] `core/constants.dart` — Hằng số toàn cục
- [x] `core/theme.dart` — Dark theme
- [x] `core/router.dart` — GoRouter + BottomNav
- [x] `models/` — ValveModel, PumpModel, SensorModel
- [x] `services/supabase_service.dart` — CRUD + streams
- [x] `services/realtime_service.dart` — WebSocket subscriptions
- [x] `controllers/` — IrrigationController, SensorController, AutoController
- [x] `screens/` — Home, Control, Auto, History, Settings
- [x] `widgets/` — ValveCard, PumpCard, SoilGauge, WaterStatus, AutoThresholdSlider

### TODO Flutter
- [ ] Kết nối Supabase thật (điền URL + anon key)
- [ ] Test realtime updates
- [ ] Màn hình đăng nhập (nếu cần auth)
- [ ] Lịch tưới UI (ScheduleScreen)
- [ ] Thông báo push (FCM + Supabase Edge Functions)
- [ ] Build APK test

---

## Supabase — Kế hoạch 📋

- [ ] Tạo project Supabase
- [ ] Chạy `schema.sql`
- [ ] Chạy `seed.sql` để test
- [ ] Cấu hình RLS policies
- [ ] Bật Realtime cho bảng `commands`, `valve_status`
- [ ] Tạo Edge Function gửi thông báo push
- [ ] **Điều kiện bắt đầu**: Sau khi V2 ổn định

---

## Nhật ký phiên

| Ngày        | Phiên | Kết quả                                        |
|-------------|-------|------------------------------------------------|
| 2026-06-28  | 1     | Tạo toàn bộ cấu trúc project, scaffold V1–V4 |

---

## Vấn đề đang theo dõi

| ID  | Vấn đề                                   | Ưu tiên | Trạng thái |
|-----|------------------------------------------|---------|------------|
| #1  | HC-SR04 Echo 5V cần voltage divider      | Cao     | Chưa xử lý |
| #2  | GPIO 0 (BOOT) có thể gây lỗi khi reset  | Trung   | Cần kiểm tra|
| #3  | ADC ESP32 không chính xác ở 3.3V gần max | Thấp   | Cần hiệu chỉnh|
| #4  | A7670C cần SIM data để test              | Cao     | Chờ SIM    |
