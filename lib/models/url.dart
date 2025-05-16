import 'package:url_launcher/url_launcher.dart';

// Future<void> launchProductUrl(String url) async {
//   final uri = Uri.tryParse(url.trim());
//   if (uri == null || !(await canLaunchUrl(uri))) {
//     print("❗ 잘못된 URL 또는 실행 불가: $url");
//     return;
//   }

//   try {
//     await launchUrl(uri, mode: LaunchMode.externalApplication);
//     print("✅ launchUrl 성공: $url");
//   } catch (e) {
//     print("❌ launchUrl 예외: $e");
//   }
// }

Future<void> launchProductUrl(String url) async {
  final trimmed = url.trim();

  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
    print("❗ URL에 http/https 없음: $url");
    return;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    print("❗ URL 파싱 실패: $url");
    return;
  }

  if (!await canLaunchUrl(uri)) {
    print("❗ 실행할 수 없는 URL: $url");
    return;
  }

  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    print("✅ launchUrl 성공: $url");
  } catch (e) {
    print("❌ launchUrl 예외: $e");
  }
}
