# API — Giao thức lệnh & Cấu trúc Supabase

## 1. Giao thức lệnh V2 (Serial JSON)

### Format chung
```json
{ "cmd": "<tên_lệnh>", ...<tham_số> }
```

### Danh sách lệnh

| Lệnh          | Tham số                          | Ví dụ                                   |
|---------------|----------------------------------|-----------------------------------------|
| `open_valve`  | `valve`: 1–4                    | `{"cmd":"open_valve","valve":1}`        |
| `close_valve` | `valve`: 1–4                    | `{"cmd":"close_valve","valve":2}`       |
| `pump`        | `state`: true/false             | `{"cmd":"pump","state":true}`           |
| `set_mode`    | `mode`: "auto"/"manual"         | `{"cmd":"set_mode","mode":"auto"}`      |
| `stop_all`    | —                               | `{"cmd":"stop_all"}`                    |
| `status`      | —                               | `{"cmd":"status"}`                      |

### Response JSON từ firmware
```json
{
  "event": "status",
  "mode": "AUTO",
  "pump": false,
  "water_level": 75.2,
  "temp": 28.5,
  "humidity": 65.3,
  "valves": [true, false, false, false],
  "moisture": [45, 62, 28, 71]
}
```

---

## 2. Supabase REST API

Base URL: `https://<project>.supabase.co/rest/v1/`  
Auth header: `apikey: <anon_key>`

### GET — Lấy trạng thái van
```http
GET /valve_status?device_id=eq.esp32-node-01&select=*
```

### POST — Gửi lệnh
```http
POST /commands
Content-Type: application/json
Prefer: return=minimal

{
  "device_id": "esp32-node-01",
  "cmd": "open_valve",
  "payload": { "valve": 1 },
  "status": "pending"
}
```

### POST — Ghi sensor
```http
POST /sensor_logs
Content-Type: application/json

{
  "device_id": "esp32-node-01",
  "moisture_1": 45,
  "moisture_2": 62,
  "moisture_3": 28,
  "moisture_4": 71,
  "air_temp": 28.5,
  "air_humidity": 65.3,
  "water_level": 75.2,
  "pump_on": false,
  "valve_1_open": true,
  "valve_2_open": false,
  "valve_3_open": false,
  "valve_4_open": false,
  "mode": "AUTO"
}
```

---

## 3. Supabase Realtime

### Kênh lắng nghe lệnh (firmware)
```javascript
supabase
  .channel('commands:esp32-node-01')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'commands',
    filter: 'device_id=eq.esp32-node-01'
  }, (payload) => {
    // Xử lý lệnh mới
  })
  .subscribe()
```

### Kênh lắng nghe sensor (Flutter app)
```dart
supabase
    .from('sensor_logs')
    .stream(primaryKey: ['id'])
    .eq('device_id', 'esp32-node-01')
    .order('recorded_at', ascending: false)
    .limit(1)
    .listen((rows) { /* cập nhật UI */ });
```

---

## 4. Cấu trúc bảng Supabase

### `devices`
| Cột         | Kiểu        | Mô tả              |
|-------------|-------------|--------------------|
| id          | UUID PK     | ID tự sinh         |
| device_id   | TEXT UNIQUE | "esp32-node-01"    |
| name        | TEXT        | Tên thiết bị       |
| fw_version  | TEXT        | Phiên bản firmware |
| last_seen   | TIMESTAMPTZ | Lần hoạt động cuối |

### `sensor_logs`
| Cột            | Kiểu        | Mô tả               |
|----------------|-------------|---------------------|
| id             | UUID PK     |                     |
| device_id      | TEXT FK     |                     |
| recorded_at    | TIMESTAMPTZ | Thời điểm đo        |
| moisture_1..4  | SMALLINT    | % độ ẩm đất 0-100  |
| air_temp       | NUMERIC     | °C                  |
| air_humidity   | NUMERIC     | %                   |
| water_level    | NUMERIC     | % mực nước bể       |
| pump_on        | BOOLEAN     |                     |
| valve_1..4_open| BOOLEAN     |                     |
| mode           | TEXT        | MANUAL/AUTO/EMERGENCY|

### `commands`
| Cột         | Kiểu        | Mô tả                       |
|-------------|-------------|-----------------------------|
| id          | UUID PK     |                             |
| device_id   | TEXT FK     |                             |
| cmd         | TEXT        | Tên lệnh                    |
| payload     | JSONB       | Tham số lệnh                |
| status      | TEXT        | pending/sent/ack/failed     |
| created_at  | TIMESTAMPTZ |                             |
| executed_at | TIMESTAMPTZ | Thời điểm firmware xác nhận|

---

## 5. AT Commands V4 (A7670C)

| AT Command                    | Mô tả                        |
|-------------------------------|------------------------------|
| `AT`                          | Kiểm tra kết nối             |
| `ATE0`                        | Tắt echo                     |
| `AT+CGATT?`                   | Kiểm tra GPRS attach         |
| `AT+CGDCONT=1,"IP","<APN>"`   | Cấu hình APN                 |
| `AT+HTTPINIT`                 | Khởi tạo HTTP                |
| `AT+HTTPPARA="URL","<url>"`   | Đặt URL                      |
| `AT+HTTPACTION=1`             | Thực hiện POST               |
| `AT+CMGF=1`                   | SMS text mode                |
| `AT+CMGS="<số>"`              | Gửi SMS                      |
| `AT+CGNSPWR=1`                | Bật GPS                      |
| `AT+CGNSINF`                  | Lấy thông tin GPS            |
