/// SensorModel — Dữ liệu tổng hợp từ một lần đọc cảm biến
class SensorModel {
  final String deviceId;
  final DateTime recordedAt;
  final List<int> moisture;       // % độ ẩm đất [zone0..zone3]
  final double airTemp;           // °C
  final double airHumidity;       // %
  final double waterLevel;        // % mực nước bể

  const SensorModel({
    required this.deviceId,
    required this.recordedAt,
    required this.moisture,
    required this.airTemp,
    required this.airHumidity,
    required this.waterLevel,
  });

  /// Độ ẩm đất trung bình
  double get avgMoisture =>
      moisture.isEmpty ? 0 : moisture.reduce((a, b) => a + b) / moisture.length;

  /// Cảnh báo mực nước thấp
  bool get isWaterLow => waterLevel <= 20;
  bool get isWaterCritical => waterLevel <= 10;

  /// Trạng thái độ ẩm từng khu
  String moistureStatus(int idx) {
    final v = moisture[idx];
    if (v < 25) return 'Khô — cần tưới';
    if (v < 50) return 'Hơi khô';
    if (v < 75) return 'Tốt';
    return 'Ẩm đủ';
  }

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      deviceId: json['device_id'] ?? '',
      recordedAt: DateTime.tryParse(json['recorded_at'] ?? '') ?? DateTime.now(),
      moisture: [
        (json['moisture_1'] ?? 0) as int,
        (json['moisture_2'] ?? 0) as int,
        (json['moisture_3'] ?? 0) as int,
        (json['moisture_4'] ?? 0) as int,
      ],
      airTemp:     (json['air_temp']      ?? 0.0).toDouble(),
      airHumidity: (json['air_humidity']  ?? 0.0).toDouble(),
      waterLevel:  (json['water_level']   ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'device_id':   deviceId,
    'recorded_at': recordedAt.toIso8601String(),
    'moisture_1':  moisture[0],
    'moisture_2':  moisture[1],
    'moisture_3':  moisture[2],
    'moisture_4':  moisture[3],
    'air_temp':    airTemp,
    'air_humidity':airHumidity,
    'water_level': waterLevel,
  };

  SensorModel copyWith({
    List<int>? moisture,
    double? airTemp,
    double? airHumidity,
    double? waterLevel,
  }) {
    return SensorModel(
      deviceId:    deviceId,
      recordedAt:  recordedAt,
      moisture:    moisture    ?? this.moisture,
      airTemp:     airTemp     ?? this.airTemp,
      airHumidity: airHumidity ?? this.airHumidity,
      waterLevel:  waterLevel  ?? this.waterLevel,
    );
  }

  static SensorModel get empty => SensorModel(
    deviceId: '',
    recordedAt: DateTime.now(),
    moisture: [0, 0, 0, 0],
    airTemp: 0,
    airHumidity: 0,
    waterLevel: 0,
  );
}
