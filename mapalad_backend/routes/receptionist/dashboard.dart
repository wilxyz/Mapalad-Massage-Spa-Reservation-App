import 'package:dart_frog/dart_frog.dart';
import '../../lib/firestore_rest_service.dart';
import '../../lib/utils/jwt_utils.dart';

String _formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, body: 'Method not allowed');
  }

  final authHeader = context.request.headers['authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Missing or invalid Authorization header'},
    );
  }

  final token = authHeader.substring(7);
  final payload = JwtUtils.verifyToken(token);
  if (payload == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Invalid or expired token'},
    );
  }

  final userId = payload['userId'] as String?;
  if (userId == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Invalid token payload'},
    );
  }

  final callerDoc = await FirestoreRestService.getDocument('users', userId);
  if (callerDoc == null || callerDoc['role'] != 'receptionist') {
    return Response.json(
      statusCode: 403,
      body: {'success': false, 'message': 'Receptionist access only'},
    );
  }

  final now = DateTime.now();
  final todayStr = _formatDate(now);
  final yesterdayStr = _formatDate(now.subtract(const Duration(days: 1)));

  final requestedDate = context.request.uri.queryParameters['date'];
  final filterDate = (requestedDate == null || requestedDate.isEmpty) ? todayStr : requestedDate;

  final allBookings = await FirestoreRestService.listDocuments('bookings');

  // Top Services — count non-cancelled bookings per serviceName, top 3
  final serviceCounts = <String, int>{};
  for (final booking in allBookings) {
    if (booking['status'] == 'cancelled') continue;
    final serviceName = booking['serviceName'] as String? ?? 'Unknown Service';
    serviceCounts[serviceName] = (serviceCounts[serviceName] ?? 0) + 1;
  }
  final topServicesEntries = serviceCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topServices = topServicesEntries.take(3).map((e) => {
        'serviceName': e.key,
        'bookingCount': e.value,
      }).toList();

  // Total Sales — all-time sum of price for completed bookings, across all branches
  double totalSales = 0;
  double todayCompletedSales = 0;
  double yesterdayCompletedSales = 0;
  for (final booking in allBookings) {
    if (booking['status'] != 'completed') continue;
    final price = (booking['price'] as num?)?.toDouble() ?? 0.0;
    totalSales += price;
    final appointmentDate = booking['appointmentDate'] as String? ?? '';
    if (appointmentDate == todayStr) {
      todayCompletedSales += price;
    } else if (appointmentDate == yesterdayStr) {
      yesterdayCompletedSales += price;
    }
  }

  double salesGrowthPercent = 0;
  if (yesterdayCompletedSales > 0) {
    salesGrowthPercent = ((todayCompletedSales - yesterdayCompletedSales) / yesterdayCompletedSales) * 100;
  } else if (todayCompletedSales > 0) {
    salesGrowthPercent = 100;
  }

  // Bookings Today — non-cancelled bookings with appointmentDate == today
  final bookingsTodayCount = allBookings.where((booking) {
    return booking['appointmentDate'] == todayStr && booking['status'] != 'cancelled';
  }).length;

  // Bookings list — filtered to the requested/selected date
  final filteredBookings = allBookings.where((booking) {
    return booking['appointmentDate'] == filterDate;
  }).toList()
    ..sort((a, b) => (a['createdAt'] as String? ?? '').compareTo(b['createdAt'] as String? ?? ''));

  final bookingsJson = filteredBookings.map((booking) {
    final map = Map<String, dynamic>.from(booking);
    final id = map.remove('id');
    return {'bookingId': id, ...map};
  }).toList();

  return Response.json(body: {
    'success': true,
    'topServices': topServices,
    'totalSales': totalSales,
    'salesGrowthPercent': salesGrowthPercent,
    'bookingsToday': bookingsTodayCount,
    'filterDate': filterDate,
    'bookings': bookingsJson,
  });
}