import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/health_service.dart';
import '../models/medicine.dart';
import 'local_server_config.dart';
import 'reaya_repository.dart';

class LocalServerException implements Exception {
  const LocalServerException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LocalServerRepository implements ReayaRepository {
  static const _oldFavoriteIdsKey = 'reaya.local.favoriteIds';
  static const _oldMedicinesKey = 'reaya.local.medicines';
  static const _favoritesMigratedKey = 'reaya.server.migratedFavorites';
  static const _medicinesMigratedKey = 'reaya.server.migratedMedicines';

  LocalServerRepository({http.Client? client, String? baseUrl, String? token})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? LocalServerConfig.baseUrl).replaceFirst(
        RegExp(r'/$'),
        '',
      ),
      _token = token ?? LocalServerConfig.token;

  final http.Client _client;
  final String _baseUrl;
  final String _token;

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? body,
  }) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers['content-type'] = 'application/json';
    if (_token.isNotEmpty) {
      request.headers['authorization'] = 'Bearer $_token';
    }
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected local server response.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded['error'];
        throw LocalServerException(
          message is String ? message : 'السيرفر المحلي رفض الطلب.',
        );
      }
      return decoded;
    } on LocalServerException {
      rethrow;
    } on TimeoutException {
      throw LocalServerException('انتهت مهلة الاتصال بالسيرفر $_baseUrl.');
    } on http.ClientException catch (error) {
      throw LocalServerException(
        'تعذر الاتصال بسيرفر اللابتوب على $_baseUrl. تأكد أنه يعمل وأن الجهازين على نفس الشبكة. (${error.message})',
      );
    } on FormatException {
      throw const LocalServerException('السيرفر أرسل ردًا غير صالح.');
    }
  }

  @override
  Future<List<HealthService>> getServices() async {
    final response = await _request('GET', '/api/services');
    final services = response['services'];
    if (services is! List) {
      throw const LocalServerException('قائمة الخدمات من السيرفر غير صالحة.');
    }
    return services
        .map(
          (service) =>
              HealthService.fromJson(Map<String, dynamic>.from(service as Map)),
        )
        .toList();
  }

  @override
  Future<Set<String>> getFavoriteIds() async {
    final response = await _request('GET', '/api/favorites');
    final ids = response['ids'];
    if (ids is! List) {
      throw const LocalServerException('قائمة المفضلة من السيرفر غير صالحة.');
    }
    final favorites = ids.cast<String>().toSet();
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_favoritesMigratedKey) != true) {
      final oldIds = preferences.getString(_oldFavoriteIdsKey);
      if (favorites.isEmpty && oldIds != null) {
        final storedIds = (jsonDecode(oldIds) as List<dynamic>).cast<String>();
        await saveFavoriteIds(storedIds.toSet());
        favorites.addAll(storedIds);
      }
      await preferences.setBool(_favoritesMigratedKey, true);
    }
    return favorites;
  }

  @override
  Future<void> saveFavoriteIds(Set<String> ids) async {
    await _request('PUT', '/api/favorites', body: {'ids': ids.toList()});
  }

  @override
  Future<List<Medicine>> getMedicines() async {
    final response = await _request('GET', '/api/medicines');
    final medicines = response['medicines'];
    if (medicines is! List) {
      throw const LocalServerException('قائمة الأدوية من السيرفر غير صالحة.');
    }
    final storedMedicines = medicines
        .map(
          (medicine) =>
              Medicine.fromJson(Map<String, dynamic>.from(medicine as Map)),
        )
        .toList();
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_medicinesMigratedKey) != true) {
      final oldMedicines = preferences.getString(_oldMedicinesKey);
      if (storedMedicines.isEmpty && oldMedicines != null) {
        final restoredMedicines = (jsonDecode(oldMedicines) as List<dynamic>)
            .map(
              (medicine) =>
                  Medicine.fromJson(Map<String, dynamic>.from(medicine as Map)),
            )
            .toList();
        await saveMedicines(restoredMedicines);
        storedMedicines.addAll(restoredMedicines);
      }
      await preferences.setBool(_medicinesMigratedKey, true);
    }
    return storedMedicines;
  }

  @override
  Future<void> saveMedicines(List<Medicine> medicines) async {
    await _request(
      'PUT',
      '/api/medicines',
      body: {
        'medicines': medicines.map((medicine) => medicine.toJson()).toList(),
      },
    );
  }
}
