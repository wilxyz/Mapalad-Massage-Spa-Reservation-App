class SalesPerServiceModel {
  final String serviceName;
  final double totalSales;
  final Map<String, double> salesByBranch;

  SalesPerServiceModel({
    required this.serviceName,
    required this.totalSales,
    required this.salesByBranch,
  });

  factory SalesPerServiceModel.fromJson(Map<String, dynamic> json) {
    final rawByBranch = json['salesByBranch'] as Map<String, dynamic>? ?? {};
    return SalesPerServiceModel(
      serviceName: json['serviceName'] as String? ?? '',
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      salesByBranch: rawByBranch.map(
        (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0.0),
      ),
    );
  }
}