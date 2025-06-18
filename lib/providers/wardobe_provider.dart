import 'dart:convert';
import 'package:chat_v0/models/item_model.dart';
import 'package:chat_v0/models/wardrobe_model.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WardrobeProvider with ChangeNotifier {
  final LoginStateManager? loginStateManager;
  WardrobeProvider(this.loginStateManager);

  List<Wardrobe> _wardrobes = [];

  List<Wardrobe> get wardrobes => _wardrobes;

  // 옷장 목록 조회
  Future<void> fetchWardrobes() async {
    final userId = loginStateManager?.userId;
    final authToken = loginStateManager?.accessToken;

    if (userId == null) return;

    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';
    final url = Uri.parse('http://$backendIp:8081/api/wardrobes/me');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        _wardrobes =
            data
                .map((w) => Wardrobe(id: w['id'], name: w['wardrobeName']))
                .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  // 옷장 단위 아이템 조회
  Future<List<Item>> fetchItemsByWardrobe(String wardrobeId) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';
    final url = Uri.parse(
      'http://$backendIp:8081/api/items/wardrobe/$wardrobeId',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $authToken'},
      );
      print('✅아이템 목록: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => Item.fromJson(e)).toList();
      }
    } catch (_) {}

    return [];
  }

  // 옷장 추가
  Future<void> addWardrobe(String wardrobeName) async {
    final userId = loginStateManager?.userId;
    final authToken = loginStateManager?.accessToken;
    if (userId == null) return;

    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';
    final url = Uri.parse('http://$backendIp:8081/api/wardrobes');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'userId': userId, 'wardrobeName': wardrobeName}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchWardrobes();
      } else {
        throw Exception('서버 응답 실패');
      }
    } catch (_) {}
  }

  // 옷장 삭제 전 옷 삭제
  Future<bool> deleteItem(String itemId) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'localhost';
    final uri = Uri.parse('http://$backendIp:8081/api/items/delete/$itemId');

    try {
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
    } catch (_) {}

    return false;
  }

  // 옷장 삭제
  Future<void> deleteWardrobe(String wardrobeId) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';

    final itemUrl = Uri.parse(
      'http://$backendIp:8081/api/items/wardrobe/$wardrobeId',
    );
    try {
      final itemResponse = await http.get(
        itemUrl,
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (itemResponse.statusCode == 200) {
        final List<dynamic> itemData = jsonDecode(
          utf8.decode(itemResponse.bodyBytes),
        );

        for (var item in itemData) {
          final itemId = item['id'];
          if (itemId != null) {
            final success = await deleteItem(itemId);
            if (!success) {}
          }
        }
      } else {}
    } catch (_) {}

    final url = Uri.parse('http://$backendIp:8081/api/wardrobes/$wardrobeId');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        await fetchWardrobes();
      }
    } catch (_) {}
  }
}
