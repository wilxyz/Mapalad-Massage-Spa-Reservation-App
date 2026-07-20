import 'dart:convert';
import 'google_auth_service.dart';
import 'firebase_config.dart';

class FirestoreRestService {
  static String get _baseUrl =>
      'https://firestore.googleapis.com/v1/projects/${FirebaseConfig.projectId}/databases/(default)/documents';

  static Map<String, dynamic> _encodeFields(Map<String, dynamic> data) {
    return {for (final entry in data.entries) entry.key: _encodeValue(entry.value)};
  }

  static Map<String, dynamic> _encodeValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is String) return {'stringValue': value};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is Map<String, dynamic>) {
      return {'mapValue': {'fields': _encodeFields(value)}};
    }
    if (value is List) {
      return {'arrayValue': {'values': value.map(_encodeValue).toList()}};
    }
    throw Exception('Unsupported Firestore value type: ${value.runtimeType}');
  }

  static Map<String, dynamic> _decodeFields(Map<String, dynamic> fields) {
    return {for (final entry in fields.entries) entry.key: _decodeValue(entry.value as Map<String, dynamic>)};
  }

  static dynamic _decodeValue(Map<String, dynamic> value) {
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('booleanValue')) return value['booleanValue'];
    if (value.containsKey('integerValue')) return int.parse(value['integerValue'] as String);
    if (value.containsKey('doubleValue')) return (value['doubleValue'] as num).toDouble();
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('timestampValue')) return value['timestampValue'];
    if (value.containsKey('mapValue')) {
      final mapFields = (value['mapValue'] as Map<String, dynamic>)['fields'] as Map<String, dynamic>? ?? {};
      return _decodeFields(mapFields);
    }
    if (value.containsKey('arrayValue')) {
      final values = (value['arrayValue'] as Map<String, dynamic>)['values'] as List<dynamic>? ?? [];
      return values.map((v) => _decodeValue(v as Map<String, dynamic>)).toList();
    }
    return null;
  }

  static String _docIdFromName(String name) => name.split('/').last;

  static Future<List<Map<String, dynamic>>> listDocuments(String collection) async {
    final client = await GoogleAuthService.getClient();
    final response = await client.get(Uri.parse('$_baseUrl/$collection'));
    if (response.statusCode != 200) throw Exception('Firestore list failed: ${response.body}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = (data['documents'] as List<dynamic>?) ?? [];
    return docs.map((doc) {
      final docMap = doc as Map<String, dynamic>;
      final fields = _decodeFields(docMap['fields'] as Map<String, dynamic>? ?? {});
      return {'id': _docIdFromName(docMap['name'] as String), ...fields};
    }).toList();
  }

  static Future<Map<String, dynamic>?> getDocument(String collection, String docId) async {
    final client = await GoogleAuthService.getClient();
    final response = await client.get(Uri.parse('$_baseUrl/$collection/$docId'));
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) throw Exception('Firestore get failed: ${response.body}');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = _decodeFields(data['fields'] as Map<String, dynamic>? ?? {});
    return {'id': docId, ...fields};
  }

  static Future<String> addDocument(String collection, Map<String, dynamic> data) async {
    final client = await GoogleAuthService.getClient();
    final response = await client.post(
      Uri.parse('$_baseUrl/$collection'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': _encodeFields(data)}),
    );
    if (response.statusCode != 200) throw Exception('Firestore create failed: ${response.body}');
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    return _docIdFromName(result['name'] as String);
  }

  static Future<void> setDocument(String collection, String docId, Map<String, dynamic> data) async {
    final client = await GoogleAuthService.getClient();
    final response = await client.patch(
      Uri.parse('$_baseUrl/$collection/$docId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': _encodeFields(data)}),
    );
    if (response.statusCode != 200) throw Exception('Firestore set failed: ${response.body}');
  }

  static Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    final client = await GoogleAuthService.getClient();
    final maskParams = data.keys.map((key) => 'updateMask.fieldPaths=$key').join('&');
    final response = await client.patch(
      Uri.parse('$_baseUrl/$collection/$docId?$maskParams'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fields': _encodeFields(data)}),
    );
    if (response.statusCode != 200) throw Exception('Firestore update failed: ${response.body}');
  }

  static Future<List<Map<String, dynamic>>> queryWhereEquals(
    String collection,
    String field,
    dynamic value,
  ) async {
    final client = await GoogleAuthService.getClient();
    final body = {
      'structuredQuery': {
        'from': [{'collectionId': collection}],
        'where': {
          'fieldFilter': {
            'field': {'fieldPath': field},
            'op': 'EQUAL',
            'value': _encodeValue(value),
          }
        },
      }
    };

    final response = await client.post(
      Uri.parse('$_baseUrl:runQuery'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) throw Exception('Firestore query failed: ${response.body}');

    final results = jsonDecode(response.body) as List<dynamic>;
    final docs = <Map<String, dynamic>>[];
    for (final entry in results) {
      final entryMap = entry as Map<String, dynamic>;
      if (entryMap.containsKey('document')) {
        final doc = entryMap['document'] as Map<String, dynamic>;
        final fields = _decodeFields(doc['fields'] as Map<String, dynamic>? ?? {});
        docs.add({'id': _docIdFromName(doc['name'] as String), ...fields});
      }
    }
    return docs;
  }
}