class SensorModel {
  final int soilPct;
  final bool lowWater;

  const SensorModel({
    required this.soilPct,
    required this.lowWater,
  });

  factory SensorModel.fromMap(Map<String, dynamic> map) {
    return SensorModel(
      soilPct:  map['soil_pct']  ?? 0,
      lowWater: map['low_water'] ?? false,
    );
  }
}