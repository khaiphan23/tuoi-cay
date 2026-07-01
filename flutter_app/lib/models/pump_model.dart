class PumpModel {
  final bool pumpOn;
  final bool autoMode;

  const PumpModel({
    required this.pumpOn,
    required this.autoMode,
  });

  factory PumpModel.fromMap(Map<String, dynamic> map) {
    return PumpModel(
      pumpOn:   map['pump_on']   ?? false,
      autoMode: map['auto_mode'] ?? false,
    );
  }
}