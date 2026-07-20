class BranchModel {
  final String branchId;
  final String branchName;
  final String branchAddress;

  BranchModel({
    required this.branchId,
    required this.branchName,
    required this.branchAddress,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      branchId: json['branchId'] as String,
      branchName: json['branchName'] as String,
      branchAddress: json['branchAddress'] as String,
    );
  }
}