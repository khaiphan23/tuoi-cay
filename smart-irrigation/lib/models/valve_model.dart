class ValveModel {
  final bool valve1On;
  final bool valve2On;

  const ValveModel({
    required this.valve1On,
    required this.valve2On,
  });

  factory ValveModel.fromMap(Map<String, dynamic> map) {
    return ValveModel(
      valve1On: map['valve1_on'] ?? false,
      valve2On: map['valve2_on'] ?? false,
    );
  }
}