/// ValveModel — Đại diện cho 1 van tưới
class ValveModel {
  final int index;          // 0-based
  final String name;
  bool isOpen;
  bool isLoading;

  ValveModel({
    required this.index,
    required this.name,
    this.isOpen = false,
    this.isLoading = false,
  });

  String get id => 'valve_${index + 1}';
  String get label => 'Van ${index + 1}';

  ValveModel copyWith({bool? isOpen, bool? isLoading}) {
    return ValveModel(
      index: index,
      name: name,
      isOpen: isOpen ?? this.isOpen,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  factory ValveModel.fromJson(Map<String, dynamic> json, int index) {
    final key = 'valve_${index + 1}_open';
    return ValveModel(
      index: index,
      name: 'Van ${index + 1}',
      isOpen: json[key] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'valve_${index + 1}_open': isOpen,
  };

  @override
  String toString() => 'ValveModel(index: $index, isOpen: $isOpen)';
}
