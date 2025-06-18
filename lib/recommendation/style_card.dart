import 'dart:convert';
import 'package:chat_v0/providers/favorite_provider.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchProductUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) {
    return;
  }
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (e) {
    print("❌ launchUrl 예외: $e");
  }
}

// 찜 관리
// 찜 등록
// Future<void> saveLikedRecommendation(
//   String styleKey,
//   Map<String, dynamic> styleData,
// ) async {
//   final prefs = await SharedPreferences.getInstance();
//   final savedJson = prefs.getString('liked_recommendations');
//   final Map<String, dynamic> savedMap =
//       savedJson != null ? jsonDecode(savedJson) : {};
//
//   savedMap[styleKey] = styleData;
//
//   await prefs.setString('liked_recommendations', jsonEncode(savedMap));
// }
Future<void> addFavoriteCoordination({
  required Map<String, String> outfit,
  required LoginStateManager loginStateManager,
}) async {
  final authToken = loginStateManager.accessToken;
  if (authToken == null) {
    print("🚫 인증 토큰 없음. 찜 등록 중단");
    return;
  }

  final backendIp = dotenv.env['BACKEND_IP_REC'] ?? 'localhost';
  final uri = Uri.parse(
    'http://$backendIp:8080/api/outfit/addFavoriteCoordination',
  );

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $authToken',
  };

  final body = jsonEncode(outfit);

  final request =
      http.Request('POST', uri)
        ..headers.addAll(headers)
        ..body = body;

  try {
    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      print('✅ 찜 등록 성공: $responseBody');
      print("🧥 서버 전송 outfit: $outfit");
    } else {
      print('❌ 찜 등록 실패: ${response.statusCode} ${response.reasonPhrase}');
    }
  } catch (e) {
    print('🚨 예외 발생: $e');
  }
}

//찜 해제 시 해당 스타일 제거
// Future<void> removeLikedRecommendation(String styleKey) async {
//   final prefs = await SharedPreferences.getInstance();
//   final savedJson = prefs.getString('liked_recommendations');
//   final Map<String, dynamic> savedMap =
//       savedJson != null ? jsonDecode(savedJson) : {};
//
//   savedMap.remove(styleKey);
//
//   await prefs.setString('liked_recommendations', jsonEncode(savedMap));
// }
Future<void> removeFavoriteCoordination({
  required String coordinationId,
  required LoginStateManager loginStateManager,
}) async {
  final authToken = loginStateManager.accessToken;
  if (authToken == null) {
    print("🚫 인증 토큰 없음. 찜 삭제 중단");
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
      print('🗑️ 찜 삭제 성공: $responseBody');
    } else {
      print('❌ 찜 삭제 실패: ${response.statusCode} ${response.reasonPhrase}');
    }
  } catch (_) {}
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

// 피드백 전송
Future<void> sendOutfitFeedback({
  required Map<String, String> outfit,
  required String feedback,
  required LoginStateManager loginStateManager,
}) async {
  final authToken = loginStateManager.accessToken;
  if (authToken == null) {
    print("🚫 인증 토큰 없음. 피드백 전송 중단");
    return;
  }
  final backendIp = dotenv.env['BACKEND_IP_REC'] ?? 'default_ip_address';
  final uri = Uri.parse('http://$backendIp:8080/api/outfit/feedback');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $authToken', // 실제 토큰으로 대체
  };

  final body = jsonEncode({"outfit": outfit, "feedback": feedback});
  // 디버그 로그 출력
  print('📤 피드백 전송 요청');
  print('🧥 outfit: $outfit');
  print('💬 feedback: $feedback');
  print('🔗 POST $uri');

  final request =
      http.Request('POST', uri)
        ..headers.addAll(headers)
        ..body = body;

  final response = await request.send();

  if (response.statusCode == 200) {
    final responseBody = await response.stream.bytesToString();
    print('📩 피드백 전송 성공: $responseBody');
  } else {
    print('❌ 피드백 전송 실패: ${response.statusCode} ${response.reasonPhrase}');
  }
}

class _StyleRecommendationViewState extends State<StyleRecommendationView> {
  Map<String, bool> likedStyles = {}; // 스타일 키별로 찜 여부 저장
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

            // final isLiked = likedStyles[styleKey] ?? false;
            final isLiked = Provider.of<FavoriteProvider>(
              context,
            ).isFavorite(styleKey);
            final loginStateManager = Provider.of<LoginStateManager>(
              context,
              listen: false,
            );
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
                          // IconButton(
                          //   icon: Icon(
                          //     widget.isLikedView
                          //         ? Icons.delete_outline_outlined
                          //         : (isLiked
                          //             ? Icons.favorite
                          //             : Icons.favorite_border),
                          //     color:
                          //         widget.isLikedView
                          //             ? const Color.fromARGB(255, 61, 61, 61)
                          //             : (isLiked ? Colors.red : null),
                          //   ),
                          //   onPressed: () async {
                          //     if (widget.isLikedView) {
                          //       final confirmed = await showDialog<bool>(
                          //         context: context,
                          //         builder:
                          //             (ctx) => AlertDialog(
                          //               title: Text("정말 삭제하시겠습니까?"),
                          //               content: Text("찜한 스타일이 목록에서 제거됩니다."),
                          //               actions: [
                          //                 TextButton(
                          //                   child: Text("취소"),
                          //                   onPressed:
                          //                       () => Navigator.of(
                          //                         ctx,
                          //                       ).pop(false),
                          //                 ),
                          //                 TextButton(
                          //                   child: Text("삭제"),
                          //                   onPressed:
                          //                       () =>
                          //                           Navigator.of(ctx).pop(true),
                          //                 ),
                          //               ],
                          //             ),
                          //       );
                          //
                          //       if (confirmed == true) {
                          //         removeLikedRecommendation(
                          //           styleKey,
                          //         ); // 저장소에서 제거
                          //         setState(() {
                          //           likedStyles.remove(styleKey); // 내부 상태에서도 제거
                          //           widget.responseData.remove(
                          //             styleKey,
                          //           ); // View에서도 제거
                          //         });
                          //         // 3. 안내 메시지
                          //         ScaffoldMessenger.of(context).showSnackBar(
                          //           SnackBar(content: Text("삭제되었습니다.")),
                          //         );
                          //       }
                          //     } else {
                          //       setState(() {
                          //         likedStyles[styleKey] = !isLiked;
                          //       });
                          //       if (!isLiked) {
                          //         saveLikedRecommendation(styleKey, styleData);
                          //       } else {
                          //         removeLikedRecommendation(styleKey);
                          //       }
                          //     }
                          //   },
                          // ),

                          // 찜 버튼////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                          IconButton(
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : null,
                            ),
                            onPressed: () async {
                              final favoriteProvider =
                                  Provider.of<FavoriteProvider>(
                                    context,
                                    listen: false,
                                  );
                              final clothesMap = Map<String, dynamic>.from(
                                styleData['clothes'] ?? {},
                              );
                              final Map<String, String> outfit = {};
                              clothesMap.forEach((key, value) {
                                final id = value['id'];
                                if (id != null) {
                                  outfit[key] = id;
                                }
                              });

                              if (isLiked) {
                                favoriteProvider.removeFavorite(styleKey);
                                await removeFavoriteCoordination(
                                  coordinationId: styleKey,
                                  loginStateManager: loginStateManager,
                                );
                              } else {
                                favoriteProvider.addFavorite(styleKey);
                                await addFavoriteCoordination(
                                  outfit: outfit, // top1, pants 등 포함된 Map
                                  loginStateManager: loginStateManager,
                                );
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
                                      TextSpan(text: '$itemDetails '),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              // ✅ 현재 포커스를 가지고 있는 위젯을 찾아 unfocus
                              FocusNode? currentFocus =
                                  FocusManager.instance.primaryFocus;
                              currentFocus?.unfocus();

                              // ✅ 약간의 지연 (플러터 내부 포커스 갱신 시간 확보)
                              await Future.delayed(
                                const Duration(milliseconds: 10),
                              );

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
                              // ✅ 포커스 해제
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
                                              onTap:
                                                  () => launchProductUrl(url),
                                            );
                                          },
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                            FocusScope.of(context).unfocus();
                                          },
                                          child: Text("닫기"),
                                        ),
                                      ],
                                    ),
                              );
                              // ✅ 다시 포커스 가능하게 설정
                              // focusProvider.enableFocus();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(
                                255,
                                13,
                                52,
                                3,
                              ), // 배경색 변경
                              foregroundColor: Colors.white, // 텍스트/아이콘 색 변경
                            ),
                            icon: Icon(Icons.image),
                            label: const Text('이미지 확인'),
                          ),
                          if (!widget.isLikedView)
                            TextButton.icon(
                              onPressed: () async {
                                String inputText = '';

                                final feedback = await showDialog<String>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('피드백 보내기'),
                                      content: TextField(
                                        autofocus: true,
                                        maxLines: 3,
                                        onChanged: (value) => inputText = value,
                                        decoration: InputDecoration(
                                          hintText:
                                              '이 스타일에 대한 의견을 입력해주세요. (예: 바지는 좋은데 상의가 마음에 안든다.)',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: Text('취소'),
                                        ),
                                        ElevatedButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(inputText),
                                          child: Text('제출'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (feedback != null &&
                                    feedback.trim().isNotEmpty) {
                                  final clothesMap = Map<String, dynamic>.from(
                                    styleData['clothes'] ?? {},
                                  );
                                  final Map<String, String> outfit = {};
                                  clothesMap.forEach((key, value) {
                                    final id = value['id'];
                                    if (id != null) {
                                      outfit[key] = id;
                                    }
                                  });
                                  final loginStateManager =
                                      Provider.of<LoginStateManager>(
                                        context,
                                        listen: false,
                                      );

                                  try {
                                    await sendOutfitFeedback(
                                      outfit: outfit,
                                      feedback: feedback,
                                      loginStateManager: loginStateManager,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('피드백이 전송되었습니다!')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('피드백 전송 실패: $e')),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(
                                  255,
                                  13,
                                  52,
                                  3,
                                ), // 배경색 변경
                                foregroundColor: Colors.white,
                              ),
                              icon: Icon(Icons.edit_square),
                              label: const Text('피드백 작성'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
