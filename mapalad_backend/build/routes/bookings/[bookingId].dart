import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import '../../lib/firestore_rest_service.dart';
import '../../lib/notification_service.dart';
import '../../lib/utils/jwt_utils.dart';

Future<Response> onRequest(RequestContext context, String bookingId) async {
  if (context.request.method != HttpMethod.patch && context.request.method != HttpMethod.delete) {
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
      body: {'success': false, 'message': 'Missing or invalid Authorization header'},
    );
  }

  final userId = payload['userId'] as String?;
  if (userId == null) {
    return Response.json(
      statusCode: 401,
      body: {'success': false, 'message': 'Missing or invalid Authorization header'},
    );
  }

  final callerDoc = await FirestoreRestService.getDocument('users', userId);
  final callerRole = callerDoc?['role'] as String?;

  final booking = await FirestoreRestService.getDocument('bookings', bookingId);
  if (booking == null) {
    return Response.json(
      statusCode: 404,
      body: {'success': false, 'message': 'Booking not found'},
    );
  }

  // --- NEW: DELETE path — customer only, own booking only, only when already cancelled ---
  if (context.request.method == HttpMethod.delete) {
    if (callerRole != 'customer' && callerRole != null && callerRole != '') {
      // Only customers delete their own history entries; receptionist/therapist have no delete action.
    }

    if (booking['userId'] != userId) {
      return Response.json(
        statusCode: 403,
        body: {'success': false, 'message': 'You do not have permission to delete this booking'},
      );
    }

    if (booking['status'] != 'cancelled') {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Only a cancelled booking can be deleted'},
      );
    }

    await FirestoreRestService.deleteDocument('bookings', bookingId);

    return Response.json(body: {'success': true, 'bookingId': bookingId, 'deleted': true});
  }
  // --- END NEW ---

  final body = jsonDecode(await context.request.body()) as Map<String, dynamic>;
  final serviceName = booking['serviceName'] as String? ?? 'the service';

  // --- Receptionist path: no ownership check, allows status + therapist assignment updates ---
  if (callerRole == 'receptionist') {
    final updates = <String, dynamic>{};

    if (body.containsKey('status')) {
      final newStatus = body['status'] as String?;
      if (newStatus != 'cancelled' && newStatus != 'confirmed') {
        return Response.json(
          statusCode: 400,
          body: {'success': false, 'message': 'Invalid status value'},
        );
      }

      if (newStatus == 'confirmed') {
        if (booking['status'] != 'pending') {
          return Response.json(
            statusCode: 400,
            body: {'success': false, 'message': 'Only a pending booking can be confirmed'},
          );
        }
        final effectiveTherapistId = body.containsKey('therapistId')
            ? body['therapistId'] as String?
            : booking['therapistId'] as String?;
        if (effectiveTherapistId == null || effectiveTherapistId.isEmpty) {
          return Response.json(
            statusCode: 400,
            body: {'success': false, 'message': 'A therapist must be assigned before confirming this booking'},
          );
        }
      }

      updates['status'] = newStatus;
    }

    final hasTherapistId = body.containsKey('therapistId');
    final hasTherapistName = body.containsKey('therapistName');
    if (hasTherapistId || hasTherapistName) {
      if (!hasTherapistId || !hasTherapistName) {
        return Response.json(
          statusCode: 400,
          body: {'success': false, 'message': 'therapistId and therapistName must be provided together'},
        );
      }
      updates['therapistId'] = body['therapistId'] as String?;
      updates['therapistName'] = body['therapistName'] as String?;
    }

    if (updates.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Nothing to update'},
      );
    }

    await FirestoreRestService.updateDocument('bookings', bookingId, updates);

    // --- NEW: notifications for receptionist-driven changes ---
    final customerId = booking['userId'] as String?;
    final originalTherapistId = booking['therapistId'] as String?;

    if (updates['status'] == 'confirmed') {
      if (customerId != null) {
        await NotificationService.create(
          recipientId: customerId,
          recipientRole: 'customer',
          bookingId: bookingId,
          type: 'booking_confirmed',
          title: 'Booking Confirmed',
          message: 'Your $serviceName booking has been confirmed.',
        );
      }
      await NotificationService.create(
        recipientId: null,
        recipientRole: 'receptionist',
        bookingId: bookingId,
        type: 'booking_confirmed',
        title: 'Booking Confirmed',
        message: '$serviceName is added to bookings.',
      );
    }

    if (updates['status'] == 'cancelled') {
      if (customerId != null) {
        await NotificationService.create(
          recipientId: customerId,
          recipientRole: 'customer',
          bookingId: bookingId,
          type: 'booking_cancelled_by_receptionist',
          title: 'Booking Cancelled',
          message: 'Your $serviceName booking was cancelled by the receptionist.',
        );
      }
      await NotificationService.create(
        recipientId: null,
        recipientRole: 'receptionist',
        bookingId: bookingId,
        type: 'booking_cancelled_by_receptionist',
        title: 'Cancelled Service',
        message: '$serviceName booking was cancelled.',
      );
      if (originalTherapistId != null && originalTherapistId.isNotEmpty) {
        await NotificationService.create(
          recipientId: originalTherapistId,
          recipientRole: 'therapist',
          bookingId: bookingId,
          type: 'booking_cancelled_by_receptionist',
          title: 'Cancelled Service',
          message: 'Your $serviceName booking was cancelled by the receptionist.',
        );
      }
    }

    final newTherapistId = updates['therapistId'] as String?;
    if (newTherapistId != null && newTherapistId.isNotEmpty && newTherapistId != originalTherapistId) {
      await NotificationService.create(
        recipientId: newTherapistId,
        recipientRole: 'therapist',
        bookingId: bookingId,
        type: 'booking_assigned',
        title: 'New Booking Assigned',
        message: 'You have been assigned a $serviceName booking.',
      );
    }
    // --- END NEW ---

    return Response.json(body: {'success': true, 'bookingId': bookingId, ...updates});
  }

  // --- Therapist path: can only mark their own already-confirmed bookings as completed ---
  if (callerRole == 'therapist') {
    if (booking['therapistId'] != userId) {
      return Response.json(
        statusCode: 403,
        body: {'success': false, 'message': 'You do not have permission to modify this booking'},
      );
    }

    final newStatus = body['status'] as String?;
    if (newStatus != 'completed') {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Invalid status value'},
      );
    }

    if (booking['status'] != 'confirmed') {
      return Response.json(
        statusCode: 400,
        body: {'success': false, 'message': 'Booking must be confirmed before it can be marked as completed'},
      );
    }

    await FirestoreRestService.updateDocument('bookings', bookingId, {'status': 'completed'});

    // --- NEW: notifications for a completed service ---
    final customerId = booking['userId'] as String?;
    if (customerId != null) {
      await NotificationService.create(
        recipientId: customerId,
        recipientRole: 'customer',
        bookingId: bookingId,
        type: 'booking_completed',
        title: 'Service Completed',
        message: '$serviceName is done.',
      );
    }
    await NotificationService.create(
      recipientId: null,
      recipientRole: 'receptionist',
      bookingId: bookingId,
      type: 'booking_completed',
      title: 'Service Completed',
      message: '$serviceName is done.',
    );
    await NotificationService.create(
      recipientId: userId,
      recipientRole: 'therapist',
      bookingId: bookingId,
      type: 'booking_completed',
      title: 'Service Completed',
      message: 'You marked $serviceName as completed.',
    );
    // --- END NEW ---

    return Response.json(body: {'success': true, 'bookingId': bookingId, 'status': 'completed'});
  }

  // --- Original customer path: unchanged, plus notifications ---
  if (booking['userId'] != userId) {
    return Response.json(
      statusCode: 403,
      body: {'success': false, 'message': 'You do not have permission to modify this booking'},
    );
  }

  final newStatus = body['status'] as String?;
  if (newStatus != 'cancelled') {
    return Response.json(
      statusCode: 400,
      body: {'success': false, 'message': 'Invalid status value'},
    );
  }

  await FirestoreRestService.updateDocument('bookings', bookingId, {'status': 'cancelled'});

  // --- NEW: notifications for a customer-cancelled booking ---
  await NotificationService.create(
    recipientId: userId,
    recipientRole: 'customer',
    bookingId: bookingId,
    type: 'booking_cancelled_by_customer',
    title: 'Booking Cancelled',
    message: 'You cancelled your $serviceName booking.',
  );
  await NotificationService.create(
    recipientId: null,
    recipientRole: 'receptionist',
    bookingId: bookingId,
    type: 'booking_cancelled_by_customer',
    title: 'Cancelled Service',
    message: '${booking['fullName'] ?? 'A customer'} cancelled their $serviceName.',
  );
  final therapistId = booking['therapistId'] as String?;
  if (therapistId != null && therapistId.isNotEmpty) {
    await NotificationService.create(
      recipientId: therapistId,
      recipientRole: 'therapist',
      bookingId: bookingId,
      type: 'booking_cancelled_by_customer',
      title: 'Cancelled Service',
      message: '${booking['fullName'] ?? 'The customer'} cancelled their $serviceName.',
    );
  }
  // --- END NEW ---

  return Response.json(body: {'success': true, 'bookingId': bookingId, 'status': 'cancelled'});
}