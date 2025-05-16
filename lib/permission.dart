import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static bool _hasCheckedLocation = false;

  /// 앱 실행 중 단 한 번만 위치 권한 요청
  static Future<bool> checkLocationPermissionOnce() async {
    if (_hasCheckedLocation) return await isLocationPermissionGranted();
    _hasCheckedLocation = true;

    final status = await Permission.location.status;
    if (status.isGranted) {
      print("✅ 위치 권한 허용됨");
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.location.request();
      if (result.isGranted) {
        print("✅ 사용자 허용");
        return true;
      } else {
        print("⛔ 사용자 거부 또는 '항상 확인'");
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
      print("⛔ 위치 퍼미션 영구 거부됨 → 설정으로 유도 필요");
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// 권한 요청 없이 단순히 granted 상태인지 확인
  static Future<bool> isLocationPermissionGranted() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }
}
