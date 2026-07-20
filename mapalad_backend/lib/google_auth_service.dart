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

    final Map<String, dynamic> credentialsJson;
    final envJson = Platform.environment['SERVICE_ACCOUNT_JSON']?.trim();
    if (envJson != null && envJson.isNotEmpty) {
      // Production (Render): credentials come from an environment variable.
      print('GoogleAuthService: found SERVICE_ACCOUNT_JSON in environment (${envJson.length} chars).');
      credentialsJson = jsonDecode(envJson) as Map<String, dynamic>;
    } else {
      // Local dev: fall back to the gitignored file on disk.
      print('GoogleAuthService: SERVICE_ACCOUNT_JSON not found in environment (value was ${envJson == null ? "null" : "empty after trim"}) — falling back to service-account.json file.');
      credentialsJson = jsonDecode(await File('service-account.json').readAsString()) as Map<String, dynamic>;
    }

    final credentials = ServiceAccountCredentials.fromJson(credentialsJson);
    final httpClient = HttpClient()..idleTimeout = const Duration(seconds: 20);
    final baseClient = IOClient(httpClient);
    _client = await clientViaServiceAccount(credentials, _scopes, baseClient: baseClient);
    return _client!;
  }
}