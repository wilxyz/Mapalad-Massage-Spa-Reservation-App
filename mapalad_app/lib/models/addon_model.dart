class AddOnModel {
  final String addOnId;
  final String addOnName;
  final double price;
  final String duration;

  AddOnModel({
    required this.addOnId,
    required this.addOnName,
    required this.price,
    required this.duration,
  });

  factory AddOnModel.fromJson(Map<String, dynamic> json) {
    return AddOnModel(
      addOnId: json['addOnId'] as String,
      addOnName: json['addOnName'] as String,
      price: (json['price'] as num).toDouble(),
      duration: json['duration'] as String,
    );
  }
}