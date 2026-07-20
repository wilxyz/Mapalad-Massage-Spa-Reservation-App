class TherapistModel {
  final String uid;
  final String fullName;

  TherapistModel({required this.uid, required this.fullName});

  factory TherapistModel.fromJson(Map<String, dynamic> json) {
    return TherapistModel(
      uid: json['uid'] as String,
      fullName: json['fullName'] as String,
    );
  }
}