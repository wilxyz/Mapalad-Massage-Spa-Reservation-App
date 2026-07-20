class ServiceModel {
  final String serviceId;
  final String serviceName;
  final double price;
  final String duration;
  final String categoryId;

  ServiceModel({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.duration,
    required this.categoryId,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['serviceId'] as String,
      serviceName: json['serviceName'] as String,
      price: (json['price'] as num).toDouble(),
      duration: json['duration'] as String,
      categoryId: json['categoryId'] as String,
    );
  }
}