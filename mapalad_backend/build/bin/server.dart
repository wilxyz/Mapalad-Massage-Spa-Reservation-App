// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, implicit_dynamic_list_literal

import 'dart:io';

import 'package:dart_frog/dart_frog.dart';


import '../routes/therapists.dart' as therapists;
import '../routes/therapist-schedule.dart' as therapist_schedule;
import '../routes/signup.dart' as signup;
import '../routes/services.dart' as services;
import '../routes/paladcare-messages.dart' as paladcare_messages;
import '../routes/me.dart' as me;
import '../routes/login.dart' as login;
import '../routes/index.dart' as index;
import '../routes/complete-google-signup.dart' as complete_google_signup;
import '../routes/categories.dart' as categories;
import '../routes/branches.dart' as branches;
import '../routes/add-ons.dart' as add_ons;
import '../routes/therapist/dashboard.dart' as therapist_dashboard;
import '../routes/therapist/availability.dart' as therapist_availability;
import '../routes/receptionist/dashboard.dart' as receptionist_dashboard;
import '../routes/profile/verify-otp.dart' as profile_verify_otp;
import '../routes/profile/set-password.dart' as profile_set_password;
import '../routes/profile/request-otp.dart' as profile_request_otp;
import '../routes/notifications/index.dart' as notifications_index;
import '../routes/notifications/check-reminders.dart' as notifications_check_reminders;
import '../routes/notifications/[notificationId].dart' as notifications_$notification_id;
import '../routes/google-auth/index.dart' as google_auth_index;
import '../routes/forgot-password/verify-otp.dart' as forgot_password_verify_otp;
import '../routes/forgot-password/reset-password.dart' as forgot_password_reset_password;
import '../routes/forgot-password/request-otp.dart' as forgot_password_request_otp;
import '../routes/bookings/index.dart' as bookings_index;
import '../routes/bookings/availability.dart' as bookings_availability;
import '../routes/bookings/[bookingId].dart' as bookings_$booking_id;


void main() async {
  final address = InternetAddress.anyIPv6;
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  createServer(address, port);
}

Future<HttpServer> createServer(InternetAddress address, int port) async {
  final handler = Cascade().add(buildRootHandler()).handler;
  final server = await serve(handler, address, port);
  print('\x1B[92m✓\x1B[0m Running on http://${server.address.host}:${server.port}');
  return server;
}

Handler buildRootHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..mount('/', (context) => buildHandler()(context))
    ..mount('/therapist', (context) => buildTherapistHandler()(context))
    ..mount('/receptionist', (context) => buildReceptionistHandler()(context))
    ..mount('/profile', (context) => buildProfileHandler()(context))
    ..mount('/notifications', (context) => buildNotificationsHandler()(context))
    ..mount('/google-auth', (context) => buildGoogleAuthHandler()(context))
    ..mount('/forgot-password', (context) => buildForgotPasswordHandler()(context))
    ..mount('/bookings', (context) => buildBookingsHandler()(context));
  return pipeline.addHandler(router);
}

Handler buildHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/add-ons', (context) => add_ons.onRequest(context,))..all('/branches', (context) => branches.onRequest(context,))..all('/categories', (context) => categories.onRequest(context,))..all('/complete-google-signup', (context) => complete_google_signup.onRequest(context,))..all('/login', (context) => login.onRequest(context,))..all('/me', (context) => me.onRequest(context,))..all('/paladcare-messages', (context) => paladcare_messages.onRequest(context,))..all('/services', (context) => services.onRequest(context,))..all('/signup', (context) => signup.onRequest(context,))..all('/therapist-schedule', (context) => therapist_schedule.onRequest(context,))..all('/therapists', (context) => therapists.onRequest(context,))..all('/', (context) => index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildTherapistHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/availability', (context) => therapist_availability.onRequest(context,))..all('/dashboard', (context) => therapist_dashboard.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildReceptionistHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/dashboard', (context) => receptionist_dashboard.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildProfileHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/request-otp', (context) => profile_request_otp.onRequest(context,))..all('/set-password', (context) => profile_set_password.onRequest(context,))..all('/verify-otp', (context) => profile_verify_otp.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildNotificationsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/check-reminders', (context) => notifications_check_reminders.onRequest(context,))..all('/<notificationId>', (context,notificationId,) => notifications_$notification_id.onRequest(context,notificationId,))..all('/', (context) => notifications_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildGoogleAuthHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/', (context) => google_auth_index.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildForgotPasswordHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/request-otp', (context) => forgot_password_request_otp.onRequest(context,))..all('/reset-password', (context) => forgot_password_reset_password.onRequest(context,))..all('/verify-otp', (context) => forgot_password_verify_otp.onRequest(context,));
  return pipeline.addHandler(router);
}

Handler buildBookingsHandler() {
  final pipeline = const Pipeline();
  final router = Router()
    ..all('/availability', (context) => bookings_availability.onRequest(context,))..all('/<bookingId>', (context,bookingId,) => bookings_$booking_id.onRequest(context,bookingId,))..all('/', (context) => bookings_index.onRequest(context,));
  return pipeline.addHandler(router);
}

