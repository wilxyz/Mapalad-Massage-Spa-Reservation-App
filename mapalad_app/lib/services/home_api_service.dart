import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';
import '../models/branch_model.dart';
import '../models/therapist_model.dart';
import '../models/addon_model.dart';
import '../screens/login_screen.dart';
import '../models/booking_model.dart';
import '../models/chat_message_model.dart';
import '../models/therapist_schedule_model.dart'; // provides kApiBaseUrl
import '../models/notification_model.dart';

class HomeApiService {
  static Future<List<CategoryModel>> fetchCategories() async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/categories'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = data['categories'] as List;
      return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load categories');
  }

  static Future<List<ServiceModel>> fetchServices({int? categoryId}) async {
    final uri = categoryId != null
        ? Uri.parse('$kApiBaseUrl/services?categoryId=$categoryId')
        : Uri.parse('$kApiBaseUrl/services');
    final response = await http.get(uri);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = data['services'] as List;
      return list.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load services');
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

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
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

  static Future<List<AddOnModel>> fetchAddOns() async {
    final response = await http.get(Uri.parse('$kApiBaseUrl/add-ons'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = data['addOns'] as List;
      return list.map((e) => AddOnModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load add-ons');
  }

  static Future<Map<String, String>> fetchCurrentUser() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$kApiBaseUrl/me'), headers: headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return {
        'fullName': data['fullName'] as String? ?? '',
        'email': data['email'] as String? ?? '',
      };
    }
    throw Exception(data['message'] ?? 'Failed to load profile');
  }

  static Future<List<String>> fetchTakenSlots({
    required String branchId,
    required String date,
    String? therapistId,
  }) async {
    final query = <String, String>{
      'branchId': branchId,
      'date': date,
      if (therapistId != null) 'therapistId': therapistId,
    };
    final uri = Uri.parse('$kApiBaseUrl/bookings/availability').replace(queryParameters: query);
    final response = await http.get(uri);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return List<String>.from(data['takenSlots'] as List);
    }
    throw Exception(data['message'] ?? 'Failed to load availability');
  }

  static Future<String> createBooking(Map<String, dynamic> bookingData) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/bookings'),
      headers: headers,
      body: jsonEncode(bookingData),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['bookingId'] as String;
    }
    throw Exception(data['message'] ?? 'Failed to create booking');
  }

  static Future<List<BookingModel>> fetchMyBookings() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$kApiBaseUrl/bookings'), headers: headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = data['bookings'] as List;
      return list.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load booking history');
  }

  static Future<void> cancelBooking(String bookingId) async {
    final headers = await _authHeaders();
    final response = await http.patch(
      Uri.parse('$kApiBaseUrl/bookings/$bookingId'),
      headers: headers,
      body: jsonEncode({'status': 'cancelled'}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to cancel booking');
    }
  }
  static Future<void> deleteBooking(String bookingId) async {
    final headers = await _authHeaders();
    final response = await http.delete(
      Uri.parse('$kApiBaseUrl/bookings/$bookingId'),
      headers: headers,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to delete booking');
    }
  }

  static Future<Map<String, dynamic>> fetchProfile() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$kApiBaseUrl/me'), headers: headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return {
        'fullName': data['fullName'] as String? ?? '',
        'email': data['email'] as String? ?? '',
        'profilePicture': data['profilePicture'] as String?,
        'role': data['role'] as String? ?? '',
      };
    }
    throw Exception(data['message'] ?? 'Failed to load profile');
  }

  static Future<void> updateProfile({
    String? fullName,
    String? email,
    String? profilePicture,
    String? verificationToken,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{
      if (fullName != null) 'fullName': fullName,
      if (email != null) 'email': email,
      if (profilePicture != null) 'profilePicture': profilePicture,
      if (verificationToken != null) 'verificationToken': verificationToken,
    };
    final response = await http.patch(
      Uri.parse('$kApiBaseUrl/me'),
      headers: headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update profile');
    }
  }

  static Future<void> requestProfileOtp({
    required String purpose,
    String? newEmail,
    String? verificationToken,
  }) async {
    final headers = await _authHeaders();
    final body = <String, dynamic>{
      'purpose': purpose,
      if (newEmail != null) 'newEmail': newEmail,
      if (verificationToken != null) 'verificationToken': verificationToken,
    };
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/profile/request-otp'),
      headers: headers,
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to send OTP');
    }
  }

  static Future<String> verifyProfileOtp({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/profile/verify-otp'),
      headers: headers,
      body: jsonEncode({'email': email, 'otp': otp, 'purpose': purpose}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      return data['verificationToken'] as String;
    }
    throw Exception(data['message'] ?? 'Invalid OTP');
  }

  static Future<void> setNewPassword({
    required String newPassword,
    required String verificationToken,
  }) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/profile/set-password'),
      headers: headers,
      body: jsonEncode({'newPassword': newPassword, 'verificationToken': verificationToken}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update password');
    }
  }
  static Future<List<ChatMessageModel>> fetchChatMessages() async {
    final headers = await _authHeaders();
    final response = await http.get(Uri.parse('$kApiBaseUrl/paladcare-messages'), headers: headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = data['messages'] as List;
      return list.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load chat history');
  }

  static Future<void> sendChatMessage({required String sender, required String message}) async {
    final headers = await _authHeaders();
    final response = await http.post(
      Uri.parse('$kApiBaseUrl/paladcare-messages'),
      headers: headers,
      body: jsonEncode({'sender': sender, 'message': message}),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to save message');
    }
  }

  static Future<List<TherapistScheduleModel>> fetchTherapistSchedule(String date) async {
    final uri = Uri.parse('$kApiBaseUrl/therapist-schedule').replace(queryParameters: {'date': date});
    final response = await http.get(uri);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] == true) {
      final list = data['schedule'] as List;
      return list.map((e) => TherapistScheduleModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(data['message'] ?? 'Failed to load therapist schedule');
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

  static Future<void> checkReminders() async {
    final headers = await _authHeaders();
    final response = await http.post(Uri.parse('$kApiBaseUrl/notifications/check-reminders'), headers: headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to check reminders');
    }
  }
}