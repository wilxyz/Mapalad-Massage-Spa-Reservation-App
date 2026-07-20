import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/booking_model.dart';
import '../models/therapist_schedule_model.dart';
import '../models/notification_model.dart';
import '../screens/login_screen.dart';  // provides kApiBaseUrl

class TherapistApiService {
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static Future<List<BookingModel>> fetchBookings({String? date}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$kApiBaseUrl/therapist/dashboard').replace(
      queryParameters: date != null ? {'date': date} : null,
    );
    final response = await http.get(uri, headers: headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = data['bookings'] as List;
      return list.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load bookings');
  }

  static Future<TherapistScheduleModel> fetchMySchedule({required String date}) async {
    final headers = await _authHeaders();
    final response = await http.get(
      Uri.parse('$kApiBaseUrl/therapist/availability?date=$date'),
      headers: headers,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return TherapistScheduleModel.fromJson(data['schedule'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Failed to load schedule');
  }
  static Future<void> updateBookingStatus(String bookingId, String status) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$kApiBaseUrl/bookings/$bookingId'),
      headers: headers,
      body: jsonEncode({'status': status}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update booking');
    }
  }

  static Future<List<NotificationModel>> fetchNotifications() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$kApiBaseUrl/notifications'), headers: headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = data['notifications'] as List;
      return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load notifications');
  }

  static Future<void> markNotificationRead(String notificationId) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$kApiBaseUrl/notifications/$notificationId'),
      headers: headers,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update notification');
    }
  }
}