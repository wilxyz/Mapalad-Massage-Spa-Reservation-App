class TopServiceModel {
  final String serviceName;
  final int bookingCount;

  TopServiceModel({required this.serviceName, required this.bookingCount});

  factory TopServiceModel.fromJson(Map<String, dynamic> json) {
    return TopServiceModel(
      serviceName: json['serviceName'] as String? ?? '',
      bookingCount: (json['bookingCount'] as num?)?.toInt() ?? 0,
    );
  }
}