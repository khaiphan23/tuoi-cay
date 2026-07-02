-- ═══════════════════════════════════════════════════════════
-- Supabase Seed Data — Smart Irrigation System
-- Dùng để test local / staging
-- Chạy sau schema.sql
-- ═══════════════════════════════════════════════════════════

-- ─── 1. Thiết bị mẫu ───────────────────────────────────────
INSERT INTO devices (device_id, name, fw_version, location) VALUES
    ('esp32-node-01', 'Khu vườn A - Rau xanh',   '2.0.0', 'Vườn phía Đông'),
    ('esp32-node-02', 'Khu vườn B - Cây ăn quả', '2.0.0', 'Vườn phía Tây'),
    ('esp32-4g-01',   'Trạm từ xa - 4G',          '4.0.0', 'Cánh đồng xa')
ON CONFLICT (device_id) DO NOTHING;

-- ─── 2. Trạng thái van ban đầu ────────────────────────────
INSERT INTO valve_status (device_id, valve_1_open, valve_2_open, valve_3_open, valve_4_open, pump_on, mode)
VALUES
    ('esp32-node-01', false, false, false, false, false, 'MANUAL'),
    ('esp32-node-02', false, false, false, false, false, 'AUTO'),
    ('esp32-4g-01',   false, false, false, false, false, 'MANUAL')
ON CONFLICT (device_id) DO NOTHING;

-- ─── 3. Cấu hình AUTO ngưỡng mẫu ─────────────────────────
INSERT INTO auto_config (device_id, zone, low_thresh, high_thresh, enabled) VALUES
    ('esp32-node-01', 1, 30, 70, true),
    ('esp32-node-01', 2, 25, 65, true),
    ('esp32-node-01', 3, 35, 75, false),
    ('esp32-node-01', 4, 30, 70, true),
    ('esp32-node-02', 1, 40, 80, true),
    ('esp32-node-02', 2, 40, 80, true),
    ('esp32-node-02', 3, 40, 80, true),
    ('esp32-node-02', 4, 40, 80, true)
ON CONFLICT (device_id, zone) DO NOTHING;

-- ─── 4. Lịch tưới mẫu ────────────────────────────────────
INSERT INTO schedules (device_id, zone, cron_expr, duration_min, enabled) VALUES
    ('esp32-node-01', 1, '0 6 * * *',  20, true),   -- 6:00 sáng mỗi ngày
    ('esp32-node-01', 2, '0 6 * * *',  20, true),
    ('esp32-node-01', 3, '30 6 * * *', 15, true),   -- 6:30 sáng
    ('esp32-node-01', 4, '30 6 * * *', 15, true),
    ('esp32-node-01', 1, '0 17 * * *', 15, true),   -- 5:00 chiều
    ('esp32-node-02', 1, '0 7 * * 1,3,5', 30, true) -- Thứ 2,4,6 lúc 7:00
ON CONFLICT DO NOTHING;

-- ─── 5. Dữ liệu sensor giả 24h qua ───────────────────────
INSERT INTO sensor_logs (
    device_id, recorded_at,
    moisture_1, moisture_2, moisture_3, moisture_4,
    air_temp, air_humidity, water_level,
    pump_on, valve_1_open, valve_2_open, valve_3_open, valve_4_open, mode
)
SELECT
    'esp32-node-01',
    NOW() - INTERVAL '1 hour' * generate_series,
    -- Độ ẩm dao động ngẫu nhiên
    40 + (random() * 40)::int,
    35 + (random() * 40)::int,
    30 + (random() * 50)::int,
    45 + (random() * 35)::int,
    -- Nhiệt độ: 25-35°C ban ngày, 20-25°C ban đêm
    CASE WHEN (EXTRACT(HOUR FROM NOW() - INTERVAL '1 hour' * generate_series) BETWEEN 8 AND 18)
         THEN 25 + (random() * 10)
         ELSE 20 + (random() * 5) END,
    55 + (random() * 30),   -- Độ ẩm không khí 55-85%
    60 + (random() * 40),   -- Mực nước bể 60-100%
    false, false, false, false, false,
    'AUTO'
FROM generate_series(1, 24);

-- ─── 6. Lệnh mẫu để test ─────────────────────────────────
INSERT INTO commands (device_id, cmd, payload, status) VALUES
    ('esp32-node-01', 'open_valve',  '{"valve": 1}',           'ack'),
    ('esp32-node-01', 'close_valve', '{"valve": 1}',           'ack'),
    ('esp32-node-01', 'set_mode',    '{"mode": "auto"}',       'ack'),
    ('esp32-node-01', 'pump',        '{"state": true}',        'ack'),
    ('esp32-node-01', 'stop_all',    '{}',                     'ack'),
    ('esp32-node-02', 'set_mode',    '{"mode": "manual"}',     'pending');
