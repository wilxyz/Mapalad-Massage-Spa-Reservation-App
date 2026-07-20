class BookingModel {
  final String bookingId;
  final String serviceId;
  final String serviceName;
  final String? categoryName;
  final String duration;
  final double price;
  final String branchId;
  final String branchName;
  final String? therapistId;
  final String? therapistName;
  final String appointmentDate;
  final String timeSlot;
  final String? addOnId;
  final String? addOnName;
  final String fullName;
  final String contactNumber;
  final String? email;
  final String? specialRequests;
  final String status;
  final String createdAt;

  BookingModel({
    required this.bookingId,
    required this.serviceId,
    required this.serviceName,
    this.categoryName,
    required this.duration,
    required this.price,
    required this.branchId,
    required this.branchName,
    this.therapistId,
    this.therapistName,
    required this.appointmentDate,
    required this.timeSlot,
    this.addOnId,
    this.addOnName,
    required this.fullName,
    required this.contactNumber,
    this.email,
    this.specialRequests,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['bookingId'] as String,
      serviceId: json['serviceId'] as String? ?? '',
      serviceName: json['serviceName'] as String? ?? '',
      categoryName: json['categoryName'] as String?,
      duration: json['duration'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      branchId: json['branchId'] as String? ?? '',
      branchName: json['branchName'] as String? ?? '',
      therapistId: json['therapistId'] as String?,
      therapistName: json['therapistName'] as String?,
      appointmentDate: json['appointmentDate'] as String? ?? '',
      timeSlot: json['timeSlot'] as String? ?? '',
      addOnId: json['addOnId'] as String?,
      addOnName: json['addOnName'] as String?,
      fullName: json['fullName'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      email: json['email'] as String?,
      specialRequests: json['specialRequests'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  DateTime get appointmentDateTime => DateTime.tryParse(appointmentDate) ?? DateTime.now();
}