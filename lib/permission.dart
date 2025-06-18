import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static bool _hasCheckedLocation = false;

  /// 앱 실행 중 단 한 번만 위치 권한 요청
  static Future<bool> checkLocationPermissionOnce() async {
    if (_hasCheckedLocation) return await isLocationPermissionGranted();
    _hasCheckedLocation = true;

    final status = await Permission.location.status;
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.location.request();
      if (result.isGranted) {
        return true;
      } else {
        return false;
      }
    }

    if (status.isPermanentlyDenied) {
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
