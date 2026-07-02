# Hardware — Linh kiện & Sơ đồ đấu dây

## Danh sách linh kiện

| STT | Linh kiện                     | Số lượng | Ghi chú                        |
|-----|-------------------------------|----------|--------------------------------|
| 1   | ESP32 WROOM-32 DevKit         | 1        | Vi điều khiển chính            |
| 2   | Relay module 4 kênh 5V        | 1        | Điều khiển 4 van               |
| 3   | Relay module 1 kênh 5V        | 1        | Điều khiển bơm                 |
| 4   | Van điện từ 12V DC (NC)       | 4        | Van tưới khu 1–4               |
| 5   | Bơm nước mini 12V DC          | 1        | Bơm chính                      |
| 6   | Cảm biến độ ẩm đất v1.2       | 4        | Đầu ra analog (0–3.3V)         |
| 7   | Cảm biến siêu âm HC-SR04      | 1        | Đo mực nước bể                 |
| 8   | DHT22 (AM2302)                | 1        | Nhiệt độ & độ ẩm không khí     |
| 9   | Cảm biến lưu lượng YF-S201    | 1        | Đếm xung (tùy chọn)            |
| 10  | Nguồn 12V 5A                  | 1        | Cấp cho van + bơm              |
| 11  | Mạch hạ áp LM2596 12V→5V     | 1        | Cấp cho ESP32 + Relay          |
| 12  | LED 5mm (xanh lá, vàng, đỏ)  | 3        | LED trạng thái                 |
| 13  | Nút bấm 12mm                  | 2        | Dừng khẩn cấp + chuyển mode   |
| 14  | Tụ 100µF 25V                  | 2        | Lọc nguồn relay                |
| 15  | Điện trở 10kΩ                 | 4        | Pull-up nút bấm                |
| 16  | Hộp chống nước IP65           | 1        | Vỏ đặt thiết bị               |
| 17  | Module 4G A7670C              | 1        | **V4 only** — thay thế WiFi    |

---

## Sơ đồ đấu dây (ESP32)

```
ESP32 WROOM-32
────────────────────────────────────────────
GPIO 25 ─── IN1 Relay 4-kênh ─── Van 1
GPIO 26 ─── IN2 Relay 4-kênh ─── Van 2
GPIO 27 ─── IN3 Relay 4-kênh ─── Van 3
GPIO 14 ─── IN4 Relay 4-kênh ─── Van 4
GPIO 13 ─── IN1 Relay 1-kênh ─── Bơm

GPIO 34 ─── AOUT Cảm biến ẩm 1 (ADC only, không dùng được làm OUTPUT)
GPIO 35 ─── AOUT Cảm biến ẩm 2
GPIO 32 ─── AOUT Cảm biến ẩm 3
GPIO 33 ─── AOUT Cảm biến ẩm 4

GPIO  5 ─── TRIG HC-SR04
GPIO 18 ─── ECHO HC-SR04 (3.3V logic — dùng voltage divider nếu cần)

GPIO  4 ─── DATA DHT22
GPIO 19 ─── PULSE Cảm biến lưu lượng

GPIO  2 ─── LED trạng thái (onboard)
GPIO 21 ─── LED AUTO mode
GPIO 22 ─── LED WiFi (V3+)

GPIO  0 ─── BTN Mode (BOOT button, INPUT_PULLUP)
GPIO 15 ─── BTN Dừng khẩn cấp (INPUT_PULLUP)

GPIO 16 ─── RX UART2 ← A7670C TX (V4)
GPIO 17 ─── TX UART2 → A7670C RX (V4)
GPIO 23 ─── PWRKEY A7670C (V4)
────────────────────────────────────────────
3.3V  ─── VCC DHT22, VCC Cảm biến ẩm (3.3V)
GND   ─── GND chung
VIN/5V ── VCC Relay module (qua LM2596)
```

---

## Sơ đồ nguồn điện

```
220VAC
    │
    └── Adapter 12V 5A
              │
              ├── Van điện từ × 4 (qua relay)
              ├── Bơm 12V (qua relay)
              │
              └── LM2596 Buck 12V→5V
                        │
                        ├── ESP32 VIN (5V)
                        └── Relay module VCC (5V)
```

> **⚠ Lưu ý**: Relay Active LOW — mặc định HIGH = tắt thiết bị.  
> Luôn đặt relay HIGH khi khởi động để tránh khởi động nhầm.

---

## Lưu ý thi công

1. **HC-SR04**: Hoạt động ở 5V. Echo output ra 5V → dùng voltage divider (10kΩ + 20kΩ) về 3.3V trước khi vào GPIO ESP32.
2. **GPIO 34, 35**: Input-only, không dùng làm output.
3. **GPIO 0**: BOOT button — nhấn khi reset để vào flash mode. Cẩn thận khi dùng làm input thông thường.
4. **DHT22**: Thêm điện trở pull-up 4.7kΩ giữa DATA và VCC.
5. **Chống nhiễu relay**: Thêm diode 1N4007 song song với cuộn dây relay (chiều ngược) để chống xung ngược khi tắt.
