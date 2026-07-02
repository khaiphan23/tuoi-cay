-- ═══════════════════════════════════════════════════════════
-- Supabase Schema — Smart Irrigation System
-- Chạy trong: Supabase Studio → SQL Editor
-- Cập nhật: 2026-06-28
-- ═══════════════════════════════════════════════════════════

-- Bật UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ───────────────────────────────────────────────────────────
-- 1. DEVICES — Danh sách thiết bị ESP32
-- ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS devices (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id   TEXT UNIQUE NOT NULL,        -- "esp32-node-01"
    name        TEXT NOT NULL,               -- "Khu vườn A"
    fw_version  TEXT,
    location    TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    last_seen   TIMESTAMPTZ
);

-- ───────────────────────────────────────────────────────────
-- 2. SENSOR_LOGS — Lịch sử đo lường cảm biến
-- ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sensor_logs (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id    TEXT NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    recorded_at  TIMESTAMPTZ DEFAULT NOW(),

    -- Độ ẩm đất 4 khu (%)
    moisture_1   SMALLINT CHECK (moisture_1 BETWEEN 0 AND 100),
    moisture_2   SMALLINT CHECK (moisture_2 BETWEEN 0 AND 100),
    moisture_3   SMALLINT CHECK (moisture_3 BETWEEN 0 AND 100),
    moisture_4   SMALLINT CHECK (moisture_4 BETWEEN 0 AND 100),

    -- Môi trường
    air_temp      NUMERIC(5,2),             -- °C
    air_humidity  NUMERIC(5,2),             -- %
    water_level   NUMERIC(5,2),            -- % bể chứa

    -- Trạng thái thiết bị
    pump_on       BOOLEAN DEFAULT FALSE,
    valve_1_open  BOOLEAN DEFAULT FALSE,
    valve_2_open  BOOLEAN DEFAULT FALSE,
    valve_3_open  BOOLEAN DEFAULT FALSE,
    valve_4_open  BOOLEAN DEFAULT FALSE,
    mode          TEXT CHECK (mode IN ('MANUAL', 'AUTO', 'EMERGENCY')) DEFAULT 'MANUAL'
);

-- Index tìm kiếm theo thiết bị + thời gian
CREATE INDEX idx_sensor_logs_device_time ON sensor_logs (device_id, recorded_at DESC);

-- ───────────────────────────────────────────────────────────
-- 3. VALVE_STATUS — Trạng thái hiện tại của van (realtime)
-- ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS valve_status (
    device_id    TEXT PRIMARY KEY REFERENCES devices(device_id) ON DELETE CASCADE,
    valve_1_open BOOLEAN DEFAULT FALSE,
    valve_2_open BOOLEAN DEFAULT FALSE,
    valve_3_open BOOLEAN DEFAULT FALSE,
    valve_4_open BOOLEAN DEFAULT FALSE,
    pump_on      BOOLEAN DEFAULT FALSE,
    mode         TEXT DEFAULT 'MANUAL',
    updated_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ───────────────────────────────────────────────────────────
-- 4. COMMANDS — Hàng chờ lệnh từ app → firmware
-- ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS commands (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id   TEXT NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    cmd         TEXT NOT NULL,     -- "open_valve" | "close_valve" | "pump" | "set_mode" | "stop_all"
    payload     JSONB,             -- { "valve": 1 } | { "state": true } | { "mode": "auto" }
    status      TEXT CHECK (status IN ('pending', 'sent', 'ack', 'failed')) DEFAULT 'pending',
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    executed_at TIMESTAMPTZ
);

CREATE INDEX idx_commands_device_status ON commands (device_id, status, created_at DESC);

-- ───────────────────────────────────────────────────────────
-- 5. AUTO_CONFIG — Cấu hình ngưỡng AUTO cho từng khu
-- ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS auto_config (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id   TEXT NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    zone        SMALLINT NOT NULL CHECK (zone BETWEEN 1 AND 4),
    low_thresh  SMALLINT DEFAULT 30 CHECK (low_thresh BETWEEN 0 AND 100),
    high_thresh SMALLINT DEFAULT 70 CHECK (high_thresh BETWEEN 0 AND 100),
    enabled     BOOLEAN DEFAULT TRUE,
    updated_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (device_id, zone)
);

-- ───────────────────────────────────────────────────────────
-- 6. SCHEDULES — Lịch tưới định kỳ
-- ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS schedules (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id   TEXT NOT NULL REFERENCES devices(device_id) ON DELETE CASCADE,
    zone        SMALLINT NOT NULL CHECK (zone BETWEEN 1 AND 4),
    cron_expr   TEXT NOT NULL,              -- "0 6 * * *" = 6:00 mỗi sáng
    duration_min SMALLINT DEFAULT 15,       -- Thời gian tưới (phút)
    enabled     BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ───────────────────────────────────────────────────────────
-- 7. Row Level Security (RLS)
-- ───────────────────────────────────────────────────────────
ALTER TABLE devices     ENABLE ROW LEVEL SECURITY;
ALTER TABLE sensor_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE valve_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE commands    ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules   ENABLE ROW LEVEL SECURITY;

-- Policy: authenticated user có thể đọc/ghi (điều chỉnh theo yêu cầu)
CREATE POLICY "auth_all" ON devices     FOR ALL TO authenticated USING (true);
CREATE POLICY "auth_all" ON sensor_logs FOR ALL TO authenticated USING (true);
CREATE POLICY "auth_all" ON valve_status FOR ALL TO authenticated USING (true);
CREATE POLICY "auth_all" ON commands    FOR ALL TO authenticated USING (true);
CREATE POLICY "auth_all" ON auto_config FOR ALL TO authenticated USING (true);
CREATE POLICY "auth_all" ON schedules   FOR ALL TO authenticated USING (true);

-- Policy: service_role (firmware ESP32 dùng anon key) có thể INSERT sensor_logs + commands
CREATE POLICY "anon_insert_sensors"  ON sensor_logs FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon_select_commands" ON commands    FOR SELECT TO anon USING (true);
CREATE POLICY "anon_update_commands" ON commands    FOR UPDATE TO anon USING (true);
CREATE POLICY "anon_upsert_valve"    ON valve_status FOR ALL TO anon USING (true);

-- ───────────────────────────────────────────────────────────
-- 8. Realtime — Bật realtime cho bảng commands
-- ───────────────────────────────────────────────────────────
-- Chạy trong Supabase Studio → Database → Replication
-- Hoặc thêm publication thủ công:
-- ALTER PUBLICATION supabase_realtime ADD TABLE commands;
-- ALTER PUBLICATION supabase_realtime ADD TABLE valve_status;
