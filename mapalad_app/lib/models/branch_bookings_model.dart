class BranchBookingsModel {
  final String branchName;
  final int completedCount;

  BranchBookingsModel({
    required this.branchName,
    required this.completedCount,
  });

  factory BranchBookingsModel.fromJson(Map<String, dynamic> json) {
    return BranchBookingsModel(
      branchName: json['branchName'] as String? ?? '',
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
    );
  }
}