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

  /*옷장 목록 조회*/
  Future<void> fetchWardrobes() async {
    final userId = loginStateManager?.userId;
    final authToken = loginStateManager?.accessToken;

    if (userId == null) return;

    final backendIp = dotenv.env['BACKEND_IP'] ?? 'default_ip_address';
    final url = Uri.parse('http://$backendIp:8081/api/wardrobes/me');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200) {
        print('✅ 목록 불러오기 성공');
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        _wardrobes =
            data
                .map((w) => Wardrobe(id: w['id'], name: w['wardrobeName']))
                .toList();
        notifyListeners();
      } else {
        print('❗ 목록 불러오기 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❗ 서버 연결 실패: $e');
    }
  }

  /*옷장 단위 아이템 조회*/
  Future<List<Item>> fetchItemsByWardrobe(String wardrobeId) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP'] ?? 'default_ip_address';
    final url = Uri.parse(
      'http://$backendIp:8081/api/items/wardrobe/$wardrobeId',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((e) => Item.fromJson(e)).toList();
      } else {
        debugPrint('❌ 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❗ 예외: $e');
    }

    return [];
  }

  /*옷장 추가*/
  Future<void> addWardrobe(String wardrobeName) async {
    final userId = loginStateManager?.userId;
    final authToken = loginStateManager?.accessToken;
    if (userId == null) return;

    final backendIp = dotenv.env['BACKEND_IP'] ?? 'default_ip_address';
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
        print('✅ 옷장 추가 성공');
        await fetchWardrobes(); // ✅ 목록 갱신
      } else {
        throw Exception('서버 응답 실패');
      }
    } catch (e) {
      print('🚨 옷장 추가 실패: $e');
    }
  }

  /*옷장 삭제*/
  Future<void> deleteWardrobe(String wardrobeId) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP'] ?? 'default_ip_address';
    final url = Uri.parse('http://$backendIp:8081/api/wardrobes/$wardrobeId');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ 옷장 삭제 성공');
        await fetchWardrobes(); // ✅ 목록 갱신
      } else {
        print('🚨 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('🚨 삭제 요청 실패: $e');
    }
  }

  /*옷장 이름 수정*/
  void renameWardrobe(String wardrobeId, String newName) {
    final authToken = loginStateManager?.accessToken;
    int index = _wardrobes.indexWhere((w) => w.id == wardrobeId);
    if (index != -1) {
      _wardrobes[index] = Wardrobe(id: wardrobeId, name: newName);
      notifyListeners();
      // TODO: 백엔드 연동 (PATCH or PUT)
    }
  }
}
