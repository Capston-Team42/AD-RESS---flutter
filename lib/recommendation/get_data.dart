import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:chat_v0/recommendation/location_change_map.dart';
import 'package:chat_v0/permission.dart';
import 'package:chat_v0/providers/wardobe_provider.dart';
import 'package:chat_v0/recommendation/chat_view.dart';
import 'package:chat_v0/recommendation/ui_elements/cordination_type_choicechip_toggle.dart';
import 'package:chat_v0/recommendation/ui_elements/loding_card.dart';
import 'package:chat_v0/models/message_model.dart';
import 'package:chat_v0/recommendation/style_card.dart';
import 'package:chat_v0/recommendation/ui_elements/select_item_bottom_sheet.dart';
import 'package:chat_v0/recommendation/ui_elements/user_input.dart';
import 'package:chat_v0/models/item_model.dart';
import 'package:chat_v0/recommendation/ui_elements/wardrobe_multi_selector_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> _requestCalendarPermission() async {
  var status = await Permission.calendar.status;
  if (status.isDenied || status.isRestricted) {
    status = await Permission.calendar.request();
    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        // 영구 거부 시 설정 페이지로 유도 가능
        await openAppSettings();
      }
    }
  } else if (status.isPermanentlyDenied) {
    // 앱 설정에서 수동 허용 필요
    await openAppSettings();
  }
}

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({super.key});

  @override
  _RecommendationPageState createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  final DeviceCalendarPlugin _calendarPlugin = DeviceCalendarPlugin();
  final TextEditingController _userInputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  Offset _dragStart = Offset.zero;
  double _headerOffset = 0; // 처음에는 헤더가 완전히 열려있는 상태
  final backendIp = dotenv.env['BACKEND_IP_REC'];
  List<Event> _events = [];
  String? _selectedEventText; // 일정 제목
  String? _customLocationName; // 사용자 입력 위치 이름
  Map<String, dynamic>? _analyzedResult;
  int? _temperatureMin;
  int? _temperatureMax;
  String? _weatheDescription;
  String? _weatherSummary;
  final List<ChatMessage> _chatMessages = []; // 전체 말풍선 출력용
  final List<ChatMessage> _effectiveMessages = []; // 백엔드 전송용 (초기화 이후만 저장)
  final double _latitude = 37.5665;
  final double _longitude = 126.9780;
  double? _calLat;
  double? _calLon;
  String? _calTargetDate;
  String? _selectedTargetDate;
  final String _nowDate = DateTime.now().toIso8601String().split("T")[0];
  List<dynamic>? _weather;

  bool _showEventList = true;
  bool _hasSentRecommendation = false;
  final bool _resetUserInputFlag = false; //requestData에서 사용자 입력 초기화
  String _selectedCoordinationType = '기본코디'; // 기본값

  Map<String, String> coordinationTypeMap = {
    '기본코디': 'no unique coordination',
    '레이어드': 'layered coordination',
    '패턴조합': 'pattern on pattern',
    '믹스매치': 'crossover coordination',
  };

  // 선택 가능한 타입 리스트
  final List<String> _coordinationTypes = ['믹스매치', '레이어드', '패턴조합', '기본코디'];

  List<String> selectedWardrobeIds = []; // 선택된 옷장 ID들
  bool useBasicWardrobe = true; // 쇼핑몰 의류 포함 여부

  List<String> _selectedItems = []; // 선택된 옷 ID들

  bool _isDateListVisible = false;
  String _selectedDateText = '날짜 선택';

  bool _ignoreWeather = false;

  String translateWeatherDescription(
    String description,
    String main,
    String date,
  ) {
    const translationMap = {
      'clear sky': '맑음 ☀',
      'few clouds': '약간의 구름 ☁',
      'scattered clouds': '흩어진 구름 ☁',
      'broken clouds': '구름 많음 ☁',
      'overcast clouds': '흐림',
      'light rain': '약한 비 ☔',
      'moderate rain': '보통 비 ☔',
      'heavy intensity rain': '강한 비 ⛆',
      'very heavy rain': '매우 강한 비 ⛆',
      'extreme rain': '극심한 비 ⛆',
      'freezing rain': '어는 비 ⛆',
      'light snow': '약한 눈 ❄',
      'snow': '눈 ❄',
      'heavy snow': '강한 눈 ☃',
      'sleet': '진눈깨비 ❄',
      'shower rain': '소나기 ⛆',
      'light shower snow': '약한 소나기 눈 ❄',
      'shower snow': '소나기 눈 ❄',
      'mist': '안개',
      'fog': '짙은 안개',
      'haze': '연무',
      'smoke': '연기',
      'thunderstorm': '천둥번개 ⚡',
    };

    final translated = translationMap[description.toLowerCase()] ?? description;
    final needsUmbrella = [
      'rain',
      'snow',
      'drizzle',
      'thunderstorm',
    ].contains(main.toLowerCase());

    return '$date 날씨: $translated${needsUmbrella ? '\n☂️ 우산을 챙기세요!' : ''}';
  }

  List<Map<String, String>> _getDateValueList() {
    final now = DateTime.now();
    return List.generate(8, (i) {
      final date = now.add(Duration(days: i));
      final display = '${date.month}월 ${date.day}일';
      final value = date.toIso8601String().split('T')[0]; // "YYYY-MM-DD"
      return {'display': display, 'value': value};
    });
  }

  @override
  void initState() {
    super.initState();
    _initializePage();

    _inputFocusNode.addListener(() {
      if (_inputFocusNode.hasFocus) {
        setState(() {
          _showEventList = false;
        });
      }
    });
  }

  Future<void> _initializePage() async {
    await _requestCalendarPermission();
    await _loadEvents();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final allowed = await PermissionManager.checkLocationPermissionOnce();
      final wardrobeProvider = context.read<WardrobeProvider>();

      if (wardrobeProvider.wardrobes.isNotEmpty) {
        setState(() {
          selectedWardrobeIds =
              wardrobeProvider.wardrobes.map((w) => w.id).toList();
        });
      } else {
        await wardrobeProvider.fetchWardrobes();
        final loaded = wardrobeProvider.wardrobes;
        setState(() {
          selectedWardrobeIds = loaded.map((w) => w.id).toList();
        });
      }
    });
  }

  Future<void> _loadEvents() async {
    try {
      final calResult = await _calendarPlugin.retrieveCalendars();
      final calendars = calResult.data ?? [];
      final now = DateTime.now();
      final end = now.add(Duration(days: 2));
      List<Event> allEvents = [];

      for (var cal in calendars) {
        if (cal.id == null) {
          continue;
        }
        try {
          final eventResult = await _calendarPlugin.retrieveEvents(
            cal.id!,
            RetrieveEventsParams(startDate: now, endDate: end),
          );
          allEvents.addAll(eventResult.data ?? []);
        } catch (_) {}
      }

      setState(() {
        _events = allEvents;
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _analyzeWithGPT(
    String title,
    String? description,
  ) async {
    final prompt = "제목: $title\n설명: ${description ?? ''}";
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-4.1",
        "messages": [
          {
            "role": "system",
            "content":
                "다음 일정 제목과 설명에서 약속 장소를를 JSON으로 추출해줘."
                "JSON 키는 영어로 써줘: location.설명 없이 JSON만 반환해."
                "마크다운 코드블럭(```json 등)은 절대 포함하지 마.",
          },
          {"role": "user", "content": prompt},
        ],
      }),
    );
    final rawBody = utf8.decode(response.bodyBytes);
    final body = jsonDecode(rawBody);
    final content = body['choices'][0]['message']['content'];
    final cleaned = content.replaceAll(RegExp(r'```json|```'), '').trim();
    return jsonDecode(cleaned);
  }

  Future<List<dynamic>> _fetchDailyWeatherFromLatLon(
    double lat,
    double lon,
  ) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&exclude=current,minutely,hourly,alerts&units=metric&appid=${dotenv.env['OPENWEATHER_API_KEY']}',
        ),
      );

      if (res.statusCode != 200) {
        throw Exception("날씨 API 실패 (status: ${res.statusCode})");
      }

      final data = jsonDecode(res.body);
      return data['daily'];
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic>? extractFromWeather(
    List<dynamic> dailyData,
    String targetDate,
  ) {
    for (final day in dailyData) {
      final dt = day['dt']; // Unix timestamp (UTC 기준 초 단위)
      final date =
          DateTime.fromMillisecondsSinceEpoch(
            dt * 1000,
          ).toIso8601String().split('T')[0]; // "YYYY-MM-DD" 형식으로 변환

      if (date == targetDate) {
        return day;
      }
    }

    print("❗ '$targetDate'에 해당하는 날씨 정보 없음");
    return null;
  }

  void _onEventSelected(Event e) async {
    setState(() {
      _selectedEventText = e.title;
      _analyzedResult = null;
    });

    // 일정 날짜 추출
    _calTargetDate = e.start?.toIso8601String().split("T")[0];

    _calTargetDate ??= DateTime.now().toIso8601String().split("T")[0];

    final analysis = await _analyzeWithGPT(e.title ?? '', e.description);
    final location = analysis['location'] ?? "";
    // 일정에서 장소 추출
    try {
      final loc = await locationFromAddress(location);
      _calLat = loc.first.latitude;
      _calLon = loc.first.longitude;
    } catch (_) {}

    setState(() {
      _analyzedResult = analysis;
    });
  }

  Widget _buildScheduleArea() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (details) {
        _dragStart = details.globalPosition;
      },
      onVerticalDragUpdate: (details) {
        final offset = details.globalPosition - _dragStart;
        final direction = offset.direction;

        if (direction > 0.5 && !_showEventList) {
          // 아래 → 위로 슬라이드 → 리스트 보여주기
          setState(() {
            _showEventList = true;
          });
        }
        if (direction < -0.5 && _showEventList) {
          // 위 → 아래로 슬라이드 → 리스트 숨기기
          setState(() {
            _showEventList = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  "📅 일정 리스트:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Row(
                  children: [
                    Icon(
                      _showEventList ? Icons.swipe_up : Icons.swipe_down,
                      size: 16,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _showEventList ? "일정 숨기기" : "일정보기",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),

            // 일정 리스트: 포커스 여부에 따라 숨김
            if (_showEventList)
              Wrap(
                children:
                    _events.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: TextButton(
                          onPressed: () => _onEventSelected(e),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              121,
                              207,
                              232,
                              214,
                            ),
                            foregroundColor: Color.fromARGB(255, 10, 59, 55),
                          ),
                          child: Text(e.title ?? "제목 없음"),
                        ),
                      );
                    }).toList(),
              ),
            if (_selectedEventText != null) SizedBox(height: 10),
            if (_selectedEventText != null)
              Row(
                children: [
                  Text("✅ 선택된 일정: $_selectedEventText"),
                  SizedBox(width: 20),
                  SizedBox(
                    height: 20,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedEventText = null;
                        });
                      },
                      child: Icon(
                        Icons.cancel,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            if (_customLocationName != null) SizedBox(height: 8),
            if (_customLocationName != null)
              Row(
                children: [
                  Text("📍 사용자 설정 위치: "),
                  SizedBox(
                    width: 150, // 텍스트가 보여질 최대 너비 지정
                    height: 20,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        _customLocationName ?? '',
                        overflow: TextOverflow.visible,
                        softWrap: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 20,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _customLocationName = null;
                        });
                      },
                      child: const Icon(
                        Icons.cancel,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> fetchRecommendation(
    Map<String, dynamic> requestData,
    String authToken,
  ) async {
    final backendIp = dotenv.env['BACKEND_IP_REC'] ?? 'default_ip_address';
    final uri = Uri.parse("http://$backendIp:8080/api/outfit/recommend");

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authToken,
        },
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return decoded is Map
            ? decoded.map((key, value) => MapEntry(key.toString(), value))
            : <String, dynamic>{};
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    // selectedWardrobeIds가 아직 준비되지 않았으면 로딩
    if (!mounted) {
      return const Center(child: CircularProgressIndicator());
    }
    // final dateList = getDateList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context); // 이전 화면으로 돌아감
          },
          icon: Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                _ignoreWeather = !_ignoreWeather;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _ignoreWeather ? '날씨 반영 ❌' : '날씨 반영 ⭕',
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          ),
          SizedBox(width: 15),
          TextButton(
            onPressed: () {
              setState(() {
                _isDateListVisible = !_isDateListVisible;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.grey[300],
            ),
            child: Text(
              _selectedDateText,
              style: TextStyle(color: Colors.black, fontSize: 14),
            ),
          ),
          SizedBox(width: 15),
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => MapLocationPicker(
                        onLocationSelected: (lat, lon) async {
                          _weather = await _fetchDailyWeatherFromLatLon(
                            lat,
                            lon,
                          );
                        },
                        onNameSelected: (placeName) {
                          setState(() {
                            _customLocationName = placeName; // 실제 이름이 들어감
                          });
                        },
                      ),
                ),
              );
            },
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _effectiveMessages.clear(); // 전송용만 초기화 (채팅 화면은 그대로)
                _chatMessages.add(
                  ChatMessage(
                    text: '입력 내용이 초기화되었습니다.',
                    type: ChatMessageType.system,
                  ),
                );
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                });
              });
            },

            icon: Icon(Icons.restart_alt),
          ),
        ],
      ),

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ChatMessageListView(
                    topPadding: 200,
                    messages: _chatMessages,
                    scrollController: _scrollController,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            UserInputArea(
                              controller: _userInputController,
                              focusNode: _inputFocusNode,
                              onSubmit: () {
                                final input = _userInputController.text.trim();
                                if (input.isNotEmpty) {
                                  setState(() {
                                    final userMessage = ChatMessage(
                                      text: input,
                                      type: ChatMessageType.user,
                                    );
                                    _chatMessages.add(userMessage);
                                    _effectiveMessages.add(userMessage);
                                    _userInputController.clear();
                                  });

                                  //스크롤
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    _scrollController.animateTo(
                                      _scrollController
                                          .position
                                          .maxScrollExtent,
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  });
                                }
                              },
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                /*아이템 선택*/
                                Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        final loginState =
                                            Provider.of<LoginStateManager>(
                                              context,
                                              listen: false,
                                            );
                                        final userId = loginState.userId;
                                        if (userId == null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('로그인이 필요합니다.'),
                                            ),
                                          );
                                          return;
                                        }

                                        final result = await showModalBottomSheet<
                                          List<Item>
                                        >(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder:
                                              (_) =>
                                                  const SelectItemBottomSheet(),
                                        );

                                        if (result != null) {
                                          _selectedItems =
                                              result.map((e) => e.id).toList();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: const CircleBorder(),
                                        minimumSize: Size.zero,
                                        padding: const EdgeInsets.all(6),
                                        backgroundColor: Colors.grey,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                      ),
                                      child: const Icon(Icons.add, size: 18),
                                    ),
                                    if (_selectedItems.isNotEmpty)
                                      Positioned(
                                        right: 2,
                                        top: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '${_selectedItems.length}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                /*옷장 선택*/
                                WardrobeSelectorToggleButton(
                                  selectedWardrobeIds: selectedWardrobeIds,
                                  useBasicWardrobe: useBasicWardrobe,
                                  onSelectionChanged: (ids, useBasic) {
                                    setState(() {
                                      selectedWardrobeIds = ids;
                                      useBasicWardrobe = useBasic;
                                    });
                                  },
                                ),

                                SizedBox(width: 8),
                                CoordinationDropdown(
                                  options: _coordinationTypes,
                                  selected: _selectedCoordinationType,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCoordinationType = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      /*결과보기 버튼: 날씨 정보 가져오기->서버로 전송*/
                      ElevatedButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          //로딩 카드 띄우기
                          setState(() {
                            _chatMessages.add(
                              ChatMessage(
                                type: ChatMessageType.ai,
                                customWidget: LoadingStyleCard(),
                              ),
                            );
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            });
                          });
                          // 날씨 정보가 없음 -> 지도 선택 안했음!-> 일정 기반으로 가져오기 -> 현위치 기반
                          if (_weather == null || _weather!.isEmpty) {
                            if (_customLocationName != null) {
                              //선택한 장소 이름으로 다시 시도
                              final loc = await locationFromAddress(
                                _customLocationName!,
                              );
                              final lat = loc.first.latitude;
                              final lon = loc.first.longitude;
                              _weather = await _fetchDailyWeatherFromLatLon(
                                lat,
                                lon,
                              );
                            } else if (_calLat != null && _calLon != null) {
                              _weather = await _fetchDailyWeatherFromLatLon(
                                _calLat!,
                                _calLon!,
                              );
                            } else {
                              final hasPermission =
                                  await PermissionManager.isLocationPermissionGranted();
                              if (!hasPermission) {
                                _weather = await _fetchDailyWeatherFromLatLon(
                                  _latitude,
                                  _longitude,
                                ); // 서울 fallback
                              }
                              try {
                                final pos =
                                    await Geolocator.getCurrentPosition();
                                final lat = pos.latitude;
                                final lon = pos.longitude;
                                _weather = await _fetchDailyWeatherFromLatLon(
                                  lat,
                                  lon,
                                );
                              } catch (e) {
                                _weather = await _fetchDailyWeatherFromLatLon(
                                  _latitude,
                                  _longitude,
                                );
                              }
                            }
                          }

                          final date =
                              _selectedTargetDate ?? _calTargetDate ?? _nowDate;
                          final String formattedDate = date.replaceAll(
                            '-',
                            '.',
                          ); //2025-01-01 => 2025.01.01

                          if (_weather == null || _weather!.isEmpty) {
                            _ignoreWeather = true;
                          } else {
                            final dailyWeather = extractFromWeather(
                              _weather!,
                              date,
                            );
                            if (dailyWeather != null) {
                              _temperatureMin =
                                  (dailyWeather['temp']['min'] as num).toInt();
                              _temperatureMax =
                                  (dailyWeather['temp']['max'] as num).toInt();
                              final pop = dailyWeather['pop']; // 강수 확률
                              _weatheDescription =
                                  dailyWeather['weather'][0]['description'];
                              _weatherSummary = dailyWeather['summary'];
                              final main = dailyWeather['weather'][0]['main'];

                              final weatherMessage =
                                  translateWeatherDescription(
                                    _weatheDescription!,
                                    main,
                                    formattedDate,
                                  );
                              if (!_ignoreWeather) {
                                setState(() {
                                  _chatMessages.add(
                                    ChatMessage(
                                      type: ChatMessageType.ai,
                                      text: weatherMessage,
                                    ),
                                  );
                                });
                              }
                            }
                          }

                          //날씨 반영 X
                          if (_ignoreWeather) {
                            _temperatureMin = null;
                            _temperatureMax = null;
                          }

                          // 사용자 입력 합치기
                          final combinedInput = _effectiveMessages
                              .where(
                                (m) =>
                                    m.type == ChatMessageType.user &&
                                    m.text != null,
                              )
                              .map((m) => m.text!)
                              .join('\n');

                          final requestData = {
                            "minTemperature": _temperatureMin,
                            "maxTemperature": _temperatureMax,
                            "requirements": combinedInput,
                            "uniqueCoordinationType":
                                coordinationTypeMap[_selectedCoordinationType] ??
                                "",
                            "schedule": _selectedEventText ?? "",
                            "necessaryClothesIds": _selectedItems,
                            "wardrobeNames": selectedWardrobeIds,
                            "useBasicWardrobe": useBasicWardrobe,
                          };

                          final loginState = Provider.of<LoginStateManager>(
                            context,
                            listen: false,
                          );

                          final token = loginState.accessToken;
                          if (token == null) {
                            return;
                          }

                          final responseData = await fetchRecommendation(
                            requestData,
                            'Bearer $token',
                          );

                          setState(() {
                            _chatMessages.removeWhere(
                              (msg) => msg.customWidget is LoadingStyleCard,
                            );
                            _chatMessages.add(
                              ChatMessage(
                                type: ChatMessageType.ai,
                                customWidget: StyleRecommendationView(
                                  responseData: responseData,
                                ),
                              ),
                            );
                            _hasSentRecommendation = true;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          minimumSize: Size(80, 80),
                        ),
                        child: Text("결과보기"),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 헤더 영역 (슬라이드 가능하게 상단에 겹침)
            Positioned(
              top: _headerOffset,
              left: 0,
              right: 0,
              child: GestureDetector(
                onVerticalDragStart: (details) {
                  _dragStart = details.globalPosition;
                },
                onVerticalDragUpdate: (details) {
                  final offset = details.globalPosition - _dragStart;
                  setState(() {
                    _headerOffset += offset.dy;
                    _headerOffset = _headerOffset.clamp(-200, 0);
                  });
                  _dragStart = details.globalPosition;
                },
                child: Material(
                  elevation: 0.5,
                  color: Colors.white,
                  child: _buildScheduleArea(),
                ),
              ),
            ),

            // 날짜 선택 영역
            if (_isDateListVisible) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDateListVisible = false;
                    });
                  },
                  child: Container(color: Colors.black.withOpacity(0.3)),
                ),
              ),
              Positioned(
                top: _headerOffset,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.21,
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          '날짜 선택',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 12,
                                childAspectRatio: 2.0,
                              ),
                          itemCount: _getDateValueList().length,
                          itemBuilder: (context, index) {
                            final dateMap = _getDateValueList()[index];
                            final display = dateMap['display']!;
                            final value = dateMap['value']!;
                            return TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  227,
                                  242,
                                  255,
                                ),
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedDateText = display;
                                  _selectedTargetDate =
                                      value; // "YYYY-MM-DD" API 요청용
                                  _isDateListVisible = false;
                                });
                              },
                              child: Text(
                                display,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
