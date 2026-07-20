import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class GoogleAuthService {
  static http.Client? _client;

  static const _scopes = [
    'https://www.googleapis.com/auth/datastore',
    'https://www.googleapis.com/auth/identitytoolkit',
    'https://www.googleapis.com/auth/cloud-platform',
  ];

  static Future<http.Client> getClient() async {
    if (_client != null) return _client!;
    final credentialsJson = jsonDecode(await File('service-account.json').readAsString());
    final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
    final httpClient = HttpClient()..idleTimeout = const Duration(seconds: 20);
    final baseClient = IOClient(httpClient);
    _client = await clientViaServiceAccount(credentials, _scopes, baseClient: baseClient);
    return _client!;
  }
}