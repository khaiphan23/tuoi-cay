/// PumpModel — Đại diện cho bơm chính
class PumpModel {
  bool isOn;
  bool isLoading;
  DateTime? startedAt;

  PumpModel({
    this.isOn = false,
    this.isLoading = false,
    this.startedAt,
  });

  /// Thời gian bơm đã chạy (nếu đang bật)
  Duration? get runningDuration {
    if (!isOn || startedAt == null) return null;
    return DateTime.now().difference(startedAt!);
  }

  String get statusLabel => isOn ? 'Đang chạy' : 'Dừng';

  PumpModel copyWith({bool? isOn, bool? isLoading, DateTime? startedAt}) {
    return PumpModel(
      isOn: isOn ?? this.isOn,
      isLoading: isLoading ?? this.isLoading,
      startedAt: startedAt ?? (isOn == false ? null : this.startedAt),
    );
  }

  factory PumpModel.fromJson(Map<String, dynamic> json) {
    return PumpModel(
      isOn: json['pump_on'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'pump_on': isOn};
}
