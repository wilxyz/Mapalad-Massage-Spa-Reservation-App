import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/receptionist_dashboard_model.dart';
import '../models/therapist_model.dart';
import '../models/therapist_schedule_model.dart';
import '../models/notification_model.dart';
import '../models/branch_model.dart';
import '../screens/login_screen.dart';  // provides kApiBaseUrl

class ReceptionistApiService {
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  static Future<ReceptionistDashboardModel> fetchDashboard({String? date}) async {
    final headers = await _authHeaders();
    final uri = Uri.parse('$kApiBaseUrl/receptionist/dashboard').replace(
      queryParameters: date != null ? {'date': date} : null,
    );
    final response = await http.get(uri, headers: headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return ReceptionistDashboardModel.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Failed to load dashboard');
  }

  static Future<List<TherapistModel>> fetchTherapists() async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/therapists'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = data['therapists'] as List;
      return list.map((e) => TherapistModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load therapists');
  }
  static Future<List<BranchModel>> fetchBranches() async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/branches'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = data['branches'] as List;
      return list.map((e) => BranchModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load branches');
  }
  static Future<List<TherapistScheduleModel>> fetchTherapistSchedule({required String date}) async {
    final response = await http.get(
      Uri.parse('$kApiBaseUrl/therapist-schedule?date=$date'),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = data['schedule'] as List;
      return list.map((e) => TherapistScheduleModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load therapist schedule');
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

  static Future<void> assignTherapist(String bookingId, String therapistId, String therapistName) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$kApiBaseUrl/bookings/$bookingId'),
      headers: headers,
      body: jsonEncode({'therapistId': therapistId, 'therapistName': therapistName}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to assign therapist');
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