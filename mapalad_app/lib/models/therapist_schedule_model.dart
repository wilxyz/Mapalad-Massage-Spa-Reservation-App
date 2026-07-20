class TherapistScheduleModel {
  final String therapistId;
  final String fullName;
  final List<String> takenSlots;
  final List<String> availableSlots;

  TherapistScheduleModel({
    required this.therapistId,
    required this.fullName,
    required this.takenSlots,
    required this.availableSlots,
  });

  factory TherapistScheduleModel.fromJson(Map<String, dynamic> json) {
    return TherapistScheduleModel(
      therapistId: json['therapistId'] as String,
      fullName: json['fullName'] as String,
      takenSlots: List<String>.from(json['takenSlots'] as List),
      availableSlots: List<String>.from(json['availableSlots'] as List),
    );
  }
}