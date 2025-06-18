import 'package:url_launcher/url_launcher.dart';

Future<void> launchProductUrl(String url) async {
  final trimmed = url.trim();

  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
    return;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null) {
    return;
  }

  if (!await canLaunchUrl(uri)) {
    return;
  }

  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}
