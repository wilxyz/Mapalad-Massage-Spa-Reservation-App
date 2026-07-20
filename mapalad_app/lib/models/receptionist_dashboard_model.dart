import 'booking_model.dart';
import 'top_service_model.dart';

class ReceptionistDashboardModel {
  final List<TopServiceModel> topServices;
  final double totalSales;
  final double salesGrowthPercent;
  final int bookingsToday;
  final String filterDate;
  final List<BookingModel> bookings;

  ReceptionistDashboardModel({
    required this.topServices,
    required this.totalSales,
    required this.salesGrowthPercent,
    required this.bookingsToday,
    required this.filterDate,
    required this.bookings,
  });

  factory ReceptionistDashboardModel.fromJson(Map<String, dynamic> json) {
    return ReceptionistDashboardModel(
      topServices: (json['topServices'] as List)
          .map((e) => TopServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      salesGrowthPercent: (json['salesGrowthPercent'] as num?)?.toDouble() ?? 0.0,
      bookingsToday: (json['bookingsToday'] as num?)?.toInt() ?? 0,
      filterDate: json['filterDate'] as String? ?? '',
      bookings: (json['bookings'] as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}