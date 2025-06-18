import 'dart:convert';
import 'package:chat_v0/providers/favorite_provider.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchProductUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return;
  }

  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
}

// 찜 조회
Future<List<Map<String, dynamic>>> getFavoriteCoordinations({
  required LoginStateManager loginStateManager,
}) async {
  final authToken = loginStateManager.accessToken;
  if (authToken == null) {
    return [];
  }

  final backendIp = dotenv.env['BACKEND_IP_REC'] ?? 'localhost';
  final uri = Uri.parse(
    'http://$backendIp:8080/api/outfit/getFavoriteCoordinations',
  );

  final headers = {'Authorization': 'Bearer $authToken'};
  final request = http.Request('GET', uri)..headers.addAll(headers);

  try {
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final Map<String, dynamic> rawMap = jsonDecode(responseBody);
      final entries = rawMap.entries.toList();
      final List<Map<String, dynamic>> converted = [];

      for (int i = 0; i < entries.length; i++) {
        final coordinationId = entries[i].key;
        final clothesData = entries[i].value;

        if (clothesData is! Map<String, dynamic>) {
          continue;
        }

        final style = {
          'coordinationId': coordinationId,
          'title': '${i + 1}번째 스타일',
          'description': '',
          'clothes': clothesData,
        };

        converted.add(style);
      }

      return converted;
    } else {
      return [];
    }
  } catch (e) {
    return [];
  }
}

// 찜 삭제
Future<void> removeFavoriteCoordination({
  required String coordinationId,
  required LoginStateManager loginStateManager,
}) async {
  final authToken = loginStateManager.accessToken;
  if (authToken == null) {
    return;
  }

  final backendIp = dotenv.env['BACKEND_IP_REC'] ?? 'localhost';
  final uri = Uri.parse(
    'http://$backendIp:8080/api/outfit/removeFavoriteCoordination/$coordinationId',
  );

  final headers = {'Authorization': 'Bearer $authToken'};

  final request = http.Request('DELETE', uri)..headers.addAll(headers);

  try {
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
    }
  } catch (_) {}
}

class StyleLikedView extends StatefulWidget {
  final Map<String, dynamic> responseData;
  final bool isLikedView;
  const StyleLikedView({
    super.key,
    required this.responseData,
    this.isLikedView = false,
  });

  @override
  State<StyleLikedView> createState() => _StyleLikedViewState();
}

class _StyleLikedViewState extends State<StyleLikedView> {
  // Map<String, bool> likedStyles = {};
  Map<String, String> roleLabelMapping = {
    'top1': '상의 1',
    'top2': '상의 2',
    'outerwear as top1': '상의 1 (아우터)',
    'outerwear as top2': '상의 2 (아우터)',
    'pants': '바지',
    'skirt': '치마',
    'dress': '원피스',
    'outerwear1': '아우터 1',
    'outerwear2': '아우터 2',
  };
  late Map<String, dynamic> _styleMap;

  @override
  void initState() {
    super.initState();
    _styleMap = Map<String, dynamic>.from(widget.responseData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          _styleMap.entries.map((entry) {
            final styleKey = entry.key;
            final styleData = entry.value;
            final title = styleData['title'] ?? '';
            final coordinationId = styleData['coordinationId'];
            final clothes = Map<String, dynamic>.from(
              styleData['clothes'] ?? {},
            );
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                "💫 $title",
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('정말 삭제하시겠습니까?'),
                                    content: Text('해당 스타일이 목록에서 지워집니다.'),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(
                                              context,
                                            ).pop(false),
                                        child: Text('취소'),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: Text('삭제'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirm == true) {
                                await removeFavoriteCoordination(
                                  coordinationId: coordinationId,
                                  loginStateManager:
                                      context.read<LoginStateManager>(),
                                );

                                context.read<FavoriteProvider>().removeFavorite(
                                  coordinationId,
                                );

                                setState(() {
                                  _styleMap.remove(styleKey);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      ...clothes.entries.map((itemEntry) {
                        final role = itemEntry.key;
                        final item = itemEntry.value as Map<String, dynamic>;
                        final productUrl = item['productUrl'] ?? '';
                        final imageUrl = item['imageUrl'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            '${roleLabelMapping[role] ?? role}: ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (imageUrl != null &&
                                          imageUrl.isNotEmpty)
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: GestureDetector(
                                            onTap:
                                                () =>
                                                    launchProductUrl(imageUrl),
                                            child: const Text(
                                              '  ⛶ 이미지    ',
                                              style: TextStyle(
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (productUrl != null &&
                                          productUrl.isNotEmpty)
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: GestureDetector(
                                            onTap:
                                                () => launchProductUrl(
                                                  productUrl,
                                                ),
                                            child: const Text(
                                              '☍ 판매처',
                                              style: TextStyle(
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
