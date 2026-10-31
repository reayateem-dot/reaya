import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reaya/data/local_server_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'migrates existing phone data to the local laptop server once',
    () async {
      SharedPreferences.setMockInitialValues({
        'reaya.local.favoriteIds': jsonEncode(['doctor-1']),
        'reaya.local.medicines': jsonEncode([
          {
            'id': 'medicine-1',
            'name': 'دواء محفوظ',
            'dose': 'قرص',
            'times': ['08:00'],
            'remaining': 3,
            'totalQuantity': 10,
            'notes': '',
          },
        ]),
      });

      var favorites = <String>[];
      var medicines = <Map<String, dynamic>>[];
      var favoriteWrites = 0;
      var medicineWrites = 0;
      final client = MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'GET' && path == '/api/favorites') {
          return http.Response(
            jsonEncode({'ids': favorites}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.method == 'PUT' && path == '/api/favorites') {
          favoriteWrites++;
          favorites = (jsonDecode(request.body) as Map<String, dynamic>)['ids']
              .cast<String>();
          return http.Response(
            jsonEncode({'ids': favorites}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.method == 'GET' && path == '/api/medicines') {
          return http.Response(
            jsonEncode({'medicines': medicines}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (request.method == 'PUT' && path == '/api/medicines') {
          medicineWrites++;
          medicines =
              (jsonDecode(request.body) as Map<String, dynamic>)['medicines']
                  .cast<Map<String, dynamic>>();
          return http.Response(
            jsonEncode({'medicines': medicines}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('{"error":"Not found"}', 404);
      });
      final repository = LocalServerRepository(
        client: client,
        baseUrl: 'http://laptop.test',
        token: 'test-token',
      );

      expect(await repository.getFavoriteIds(), {'doctor-1'});
      expect(await repository.getMedicines(), hasLength(1));
      await repository.getFavoriteIds();
      await repository.getMedicines();

      expect(favoriteWrites, 1);
      expect(medicineWrites, 1);
      expect(favorites, ['doctor-1']);
      expect(medicines.single['name'], 'دواء محفوظ');
    },
  );
}
