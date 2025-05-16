// chat/style_card.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchProductUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    print("❗ 잘못된 URL: $url");
    return;
  }

  // 👉 canLaunchUrl() 없이 바로 실행 시도!
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    print("✅ launchUrl 성공: $url");
  } catch (e) {
    print("❌ launchUrl 예외: $e");
  }
}

// 찜 관리
// 찜한 응답 전체 저장 (JSON 단위로)
Future<void> saveLikedRecommendation(
  String styleKey,
  Map<String, dynamic> styleData,
) async {
  final prefs = await SharedPreferences.getInstance();
  final savedJson = prefs.getString('liked_recommendations');
  final Map<String, dynamic> savedMap =
      savedJson != null ? jsonDecode(savedJson) : {};

  savedMap[styleKey] = styleData;

  await prefs.setString('liked_recommendations', jsonEncode(savedMap));
}

//찜 해제 시 해당 스타일 제거
Future<void> removeLikedRecommendation(String styleKey) async {
  final prefs = await SharedPreferences.getInstance();
  final savedJson = prefs.getString('liked_recommendations');
  final Map<String, dynamic> savedMap =
      savedJson != null ? jsonDecode(savedJson) : {};

  savedMap.remove(styleKey);

  await prefs.setString('liked_recommendations', jsonEncode(savedMap));
}

// 3. 찜 내역 전체 불러오기
Future<Map<String, dynamic>> loadAllLikedRecommendations() async {
  final prefs = await SharedPreferences.getInstance();
  final savedJson = prefs.getString('liked_recommendations');
  if (savedJson == null) return {};
  return jsonDecode(savedJson);
}

class StyleRecommendationView extends StatefulWidget {
  final Map<String, dynamic> responseData;
  final bool isLikedView;
  const StyleRecommendationView({
    super.key,
    required this.responseData,
    this.isLikedView = false,
  });

  @override
  State<StyleRecommendationView> createState() =>
      _StyleRecommendationViewState();
}

class _StyleRecommendationViewState extends State<StyleRecommendationView> {
  Map<String, bool> likedStyles = {}; // 스타일 키별로 찜 여부 저장

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          widget.responseData.entries.map((entry) {
            final styleKey = entry.key;
            final styleData = entry.value;
            final title = styleData['title'] ?? '';
            final description = styleData['description'] ?? '';
            final clothes = Map<String, dynamic>.from(
              styleData['clothes'] ?? {},
            );

            final isLiked = likedStyles[styleKey] ?? false;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Card(
                // color:  Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
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
                                "💫 $title", //🌿
                                style: Theme.of(context).textTheme.titleMedium,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          SizedBox(width: 4), // 여유 공간 확보
                          IconButton(
                            icon: Icon(
                              widget.isLikedView
                                  ? Icons.delete_outline_outlined
                                  : (isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border),
                              color:
                                  widget.isLikedView
                                      ? const Color.fromARGB(255, 61, 61, 61)
                                      : (isLiked ? Colors.red : null),
                            ),
                            onPressed: () async {
                              if (widget.isLikedView) {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (ctx) => AlertDialog(
                                        title: Text("정말 삭제하시겠습니까?"),
                                        content: Text("찜한 스타일이 목록에서 제거됩니다."),
                                        actions: [
                                          TextButton(
                                            child: Text("취소"),
                                            onPressed:
                                                () => Navigator.of(
                                                  ctx,
                                                ).pop(false),
                                          ),
                                          TextButton(
                                            child: Text("삭제"),
                                            onPressed:
                                                () =>
                                                    Navigator.of(ctx).pop(true),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirmed == true) {
                                  removeLikedRecommendation(
                                    styleKey,
                                  ); // 저장소에서 제거
                                  setState(() {
                                    likedStyles.remove(styleKey); // 내부 상태에서도 제거
                                    widget.responseData.remove(
                                      styleKey,
                                    ); // View에서도 제거
                                  });
                                  // 3. 안내 메시지
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("삭제되었습니다.")),
                                  );
                                }
                              } else {
                                setState(() {
                                  likedStyles[styleKey] = !isLiked;
                                });
                                if (!isLiked) {
                                  saveLikedRecommendation(styleKey, styleData);
                                } else {
                                  removeLikedRecommendation(styleKey);
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(height: 12),
                      ...clothes.entries.map((itemEntry) {
                        final role = itemEntry.key;
                        final item = itemEntry.value as Map<String, dynamic>;
                        final itemDetails = item['text'] ?? '';
                        final productUrl = item['productUrl'] ?? '';
                        // print("📦 product_url: $productUrl");

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
                                        text: '$role: ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(text: '$itemDetails '),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: GestureDetector(
                                          onTap:
                                              () =>
                                                  launchProductUrl(productUrl),
                                          child: const Text(
                                            '🔗 판매처',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              // decoration:
                                              //     TextDecoration.underline,
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
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final imageUrls =
                              clothes.values
                                  .map((item) => item['imageUrl'])
                                  .where(
                                    (url) =>
                                        url != null &&
                                        url.toString().isNotEmpty,
                                  )
                                  .cast<String>()
                                  .toList();

                          showDialog(
                            context: context,
                            builder:
                                (ctx) => AlertDialog(
                                  title: Text("이미지 보기"),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: imageUrls.length,
                                      itemBuilder: (context, index) {
                                        final url = imageUrls[index];
                                        return ListTile(
                                          leading: Icon(Icons.image),
                                          title: Text("${index + 1}번째 옷"),
                                          onTap: () => launchProductUrl(url),
                                        );
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: Text("닫기"),
                                    ),
                                  ],
                                ),
                          );
                        },
                        child: const Text('이미지 확인'),
                      ),

                      // ElevatedButton(
                      //   onPressed: () async {
                      //     final imageUrls =
                      //         clothes.values
                      //             .map((item) => item['imageUrl'])
                      //             .where(
                      //               (url) =>
                      //                   url != null &&
                      //                   url.toString().isNotEmpty,
                      //             )
                      //             .cast<String>()
                      //             .toList();

                      //     for (final url in imageUrls) {
                      //       await launchProductUrl(url); // 안정성 있는 함수 사용
                      //     }
                      //   },

                      //   child: const Text('이미지 확인'),
                      // ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
