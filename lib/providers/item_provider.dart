import 'dart:convert';
import 'dart:io';
import 'package:chat_v0/models/item_model.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ItemProvider with ChangeNotifier {
  final LoginStateManager? loginStateManager;
  ItemProvider(this.loginStateManager);

  List<Item> _allItems = [];

  List<Item> get allItems => _allItems;

  /* 전체 아이템 불러오기 (한 번만 호출) */
  Future<void> fetchAllItems() async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP'] ?? 'localhost';
    final url = Uri.parse('http://$backendIp:8081/api/items/me');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        _allItems = data.map((e) => Item.fromJson(e)).toList();
        notifyListeners();
      } else {
        print('❗ 아이템 전체 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❗ 아이템 불러오기 오류: $e');
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

  /* 이미지 분석 */
  Future<Map<String, dynamic>?> analyzeImage(File imageFile) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP'] ?? 'localhost';
    final uri = Uri.parse('http://$backendIp:8081/api/items/analyze');

    try {
      final request =
          http.MultipartRequest('POST', uri)
            ..headers['Authorization'] = 'Bearer $authToken'
            ..files.add(
              await http.MultipartFile.fromPath('file', imageFile.path),
            );

      // ⚠️ Content-Type은 MultipartRequest가 자동 처리하므로 명시 X

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = jsonDecode(responseBody);
        debugPrint("📦 분석 결과 도착: ${jsonEncode(result)}");
        return result;
      } else {
        print('❌ 분석 실패: ${response.statusCode} $responseBody');
      }
    } catch (e) {
      print('❌ 분석 중 오류 발생: $e');
    }
    return null;
  }

  /* 옷 등록 */
  Future<bool> registerItem(Map<String, dynamic> itemData) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP'] ?? 'localhost';
    final uri = Uri.parse('http://$backendIp:8081/api/items/create');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(itemData),
      );

      if (response.statusCode == 200) {
        print('✅ 등록 성공');
        return true;
      } else {
        print('❌ 등록 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ 등록 오류: $e');
    }
    return false;
  }

  /* 아이템 정보 수정 */
  Future<bool> updateItem({
    required String itemId,
    Map<String, dynamic>? updatedFields,
  }) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP'] ?? 'localhost';
    final uri = Uri.parse('http://$backendIp:8081/api/items/update/$itemId');

    debugPrint("📤 수정 요청 전송: $updatedFields");

    try {
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedFields),
      );

      debugPrint("📬 응답 코드: ${response.statusCode}");
      debugPrint("📬 응답 본문: ${response.body}");

      if (response.statusCode == 200) {
        print('✅ 아이템 수정 성공');
        return true;
      } else {
        print('❌ 아이템 수정 실패: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ 아이템 수정 중 오류: $e');
    }

    return false;
  }

  /* 옷 삭제 */
  Future<bool> deleteItem(String itemId) async {
    final authToken = loginStateManager?.accessToken;
    final backendIp = dotenv.env['BACKEND_IP'] ?? 'localhost';
    final uri = Uri.parse('http://$backendIp:8081/api/items/delete/$itemId');

    try {
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        print('✅ 아이템 삭제 성공');
        // 선택적으로 _allItems 갱신
        _allItems.removeWhere((item) => item.id == itemId);
        notifyListeners();
        return true;
      } else {
        print('❌ 아이템 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 아이템 삭제 중 오류: $e');
    }

    return false;
  }

  /* 전체 비우기 (선택적 사용) */
  void clear() {
    _allItems = [];
    notifyListeners();
  }
}
