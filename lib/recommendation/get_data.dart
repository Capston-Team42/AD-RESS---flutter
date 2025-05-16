import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:chat_v0/menu/location_change_map.dart';
import 'package:chat_v0/permission.dart';
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
  if (!status.isGranted) {
    status = await Permission.calendar.request();
    if (!status.isGranted) {
      print("⛔ 캘린더 퍼미션 거부됨");
    }
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
  final backendIp = dotenv.env['BACKEND_IP'];
  List<Event> _events = [];
  String? _selectedEventText; // 일정 제목
  String? _customLocationName; // 사용자 입력 위치 이름
  Event? _selectedEvent;
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
  List<dynamic>? _weather;

  bool useDummyGPT = true;

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

  List<String> _selectedItems = []; // 선택된 옷 ID들들

  bool _isDateListVisible = false;
  String _selectedDateText = '날짜 선택';

  bool _ignoreWeather = false;

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
    _loadEvents();
    _requestCalendarPermission().then((_) => _loadEvents());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final allowed = await PermissionManager.checkLocationPermissionOnce();
      print("📍 위치 권한 상태: $allowed");
    });

    _inputFocusNode.addListener(() {
      // 포커스 생기면 리스트 숨기기
      if (_inputFocusNode.hasFocus) {
        setState(() {
          _showEventList = false;
        });
      }
    });
  }

  Future<void> _loadEvents() async {
    final calResult = await _calendarPlugin.retrieveCalendars();
    final calendars = calResult.data ?? [];
    final now = DateTime.now();
    final end = now.add(Duration(days: 2));
    List<Event> allEvents = [];

    for (var cal in calendars) {
      final eventResult = await _calendarPlugin.retrieveEvents(
        cal.id!,
        RetrieveEventsParams(startDate: now, endDate: end),
      );
      allEvents.addAll(eventResult.data ?? []);
    }

    setState(() {
      _events = allEvents;
    });
  }

  Future<Map<String, dynamic>> _analyzeWithGPT(
    String title,
    String? description,
  ) async {
    final prompt = "제목: $title\n설명: ${description ?? ''}";
    if (useDummyGPT) {
      print("🧠 [더미 GPT 분석 사용] 제목: $title, 설명: $description");
      await Future.delayed(Duration(seconds: 1)); // API 시뮬레이션

      // 상황에 맞는 더미 응답 (간단한 조건문 활용 가능)
      if (title.contains("점심") || description?.contains("밥") == true) {
        return {"location": "서울 을지로", "time_period": "day", "type": "lunch"};
      } else if (title.contains("회의") ||
          description?.contains("프로젝트") == true) {
        return {"location": "서울 강남역", "time_period": "day", "type": "meeting"};
      } else {
        return {"location": "홍대입구", "time_period": "night", "type": "dinner"};
      }
    } else {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "gpt-4o",
          "messages": [
            {
              "role": "system",
              "content":
                  "다음 일정 제목과 설명에서 약속 장소, 시간대(낮/밤), 약속 유형을 JSON으로 추출해줘."
                  "JSON 키는 영어로 써줘: location, time_period, type.설명 없이 JSON만 반환해."
                  "마크다운 코드블럭(```json 등)은 절대 포함하지 마.",
            },
            {"role": "user", "content": prompt},
          ],
        }),
      );
      final rawBody = utf8.decode(response.bodyBytes);
      final body = jsonDecode(rawBody);
      final content = body['choices'][0]['message']['content'];
      print("🧠 GPT 응답 원문: $content");
      final cleaned = content.replaceAll(RegExp(r'```json|```'), '').trim();
      return jsonDecode(content);
    }
  }

  // Future<List<dynamic>> _fetchWeather(String? location) async {
  //   double lat, lon;
  //
  //   // 🔹 1. 주소 기반 요청
  //   if (location != null && location.isNotEmpty) {
  //     print("✅ 날씨 정보 받아오는 장소: $location");
  //     try {
  //       final loc = await locationFromAddress(location);
  //       lat = loc.first.latitude;
  //       lon = loc.first.longitude;
  //       return await _fetchWeatherFromLatLng(lat, lon);
  //     } catch (e) {
  //       print("❗ 주소 변환 실패: $e");
  //     }
  //   }
  //
  // 🔹 2. location이 없거나 주소 변환 실패한 경우 → 현위치 요청
  //   final hasPermission = await PermissionManager.isLocationPermissionGranted();
  //   if (!hasPermission) {
  //     print("📌 퍼미션 거부 → 서울로 대체");
  //     return await _fetchWeatherFromLatLng(
  //       _latitude,
  //       _longitude,
  //     ); // 서울 fallback
  //   }
  //   try {
  //     final pos = await Geolocator.getCurrentPosition();
  //     lat = pos.latitude;
  //     lon = pos.longitude;
  //     return await _fetchWeatherFromLatLng(lat, lon);
  //   } catch (e) {
  //     print("❗ 현위치 가져오기 실패 → 서울로 대체: $e");
  //     return await _fetchWeatherFromLatLng(_latitude, _longitude);
  //   }
  // }

  // Future<Map<String, int>> _fetchWeatherFromLatLng(
  //   double lat,
  //   double lon,
  // ) async {
  //   print("✅위치: $lat, $lon");
  //   try {
  //     final res = await http.get(
  //       Uri.parse(
  //         'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&exclude=current,minutely,hourly,alerts&units=metric&appid=${dotenv.env['OPENWEATHER_API_KEY']}',
  //       ),
  //     );
  //
  //     if (res.statusCode != 200) {
  //       throw Exception("날씨 API 실패 (status: ${res.statusCode})");
  //     }
  //
  //     final data = jsonDecode(res.body);
  //     final tempMin = (data['main']['temp_min'] as num).toInt();
  //     final tempMax = (data['main']['temp_max'] as num).toInt();
  //
  //     return {"min": tempMin, "max": tempMax};
  //   } catch (e) {
  //     print("❗ 위경도 기반 날씨 요청 실패: $e");
  //     return {"min": 19, "max": 21}; // 안전한 fallback
  //   }
  // }

  Future<List<dynamic>> _fetchDailyWeatherFromLatLon(
    double lat,
    double lon,
  ) async {
    print("✅ 날씨 정보 받아오는 위도/경도: $lat, $lon");

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
      return data['daily']; // 🔹 8일치 날씨 예보 리스트만 반환
    } catch (e) {
      print("❗ 날씨 요청 실패: $e");
      return []; // 안전한 fallback
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
        // {
        //   'min': (day['temp']['min'] as num).toInt(),
        //   'max': (day['temp']['max'] as num).toInt(),
        //   'description': day['weather'][0]['description'],
        //   'main': day['weather'][0]['main'],
        //   'icon': day['weather'][0]['icon'], // 날씨 아이콘 ID
        //   'pop': ((day['pop'] ?? 0.0) as num), // 강수 확률 (0.0 ~ 1.0)
        //   'uvi': day['uvi'],                  // 자외선 지수
        //   'humidity': day['humidity'],        // 습도
        // };
      }
    }

    print("❗ '$targetDate'에 해당하는 날씨 정보 없음");
    return null;
  }

  void _onEventSelected(Event e) async {
    setState(() {
      _selectedEvent = e;
      _selectedEventText = e.title;
      _analyzedResult = null;
    });

    // 일정 날짜 추출
    _calTargetDate =
        e.start?.toIso8601String().split("T")[0]; // 예: "2025-05-17"

    if (_calTargetDate == null) {
      print("⚠️ 일정 시작 시간이 없음->오늘로 설정");
      _calTargetDate = DateTime.now().toIso8601String().split("T")[0];
    }

    final analysis = await _analyzeWithGPT(e.title ?? '', e.description);
    final location = analysis['location'] ?? "";
    // 일정에서 장소 추출
    try {
      final loc = await locationFromAddress(location);
      _calLat = loc.first.latitude;
      _calLon = loc.first.longitude;
    } catch (e) {
      print("❗ 주소 변환 실패: $e");
    }

    setState(() {
      _analyzedResult = analysis;
    });
  }

  Widget _buildScheduleArea() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // 빈 공간까지 감지
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
            Text("📅 일정 리스트:", style: TextStyle(fontWeight: FontWeight.bold)),

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
                              255,
                              227,
                              242,
                              255,
                            ),
                            // foregroundColor: Colors.black,
                          ),
                          child: Text(e.title ?? "제목 없음"),
                        ),
                      );
                    }).toList(),
              )
            else
              Row(
                children: [
                  Icon(Icons.swipe_down, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text("일정 보기", style: TextStyle(color: Colors.grey)),
                ],
              ),
            SizedBox(height: 10),
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
            SizedBox(height: 8),
            if (_customLocationName != null)
              Row(
                children: [
                  Text("📍 사용자 설정 위치: $_customLocationName"),
                  SizedBox(width: 20),
                  SizedBox(
                    height: 20,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _customLocationName = null;
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
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> fetchRecommendation(
    Map<String, dynamic> requestData,
    String authToken,
  ) async {
    final backendIp = dotenv.env['BACKEND_IP'] ?? 'default_ip_address';
    final uri = Uri.parse("http://$backendIp:8080/api/outfit/recommend");

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': authToken, // 보통은 'Bearer $authToken' 형태로
        },
        body: jsonEncode(requestData),
      );

      print(
        '🔐 최종 Authorization 헤더: ${response.request?.headers['Authorization']}',
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return decoded is Map
            ? decoded.map((key, value) => MapEntry(key.toString(), value))
            : <String, dynamic>{};
      } else {
        print("❌ 서버 오류: ${response.statusCode}");
        print("📨 응답 본문: ${utf8.decode(response.bodyBytes)}");
        return {};
      }
    } catch (e) {
      print("❗ 예외 발생: $e");
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    // final dateList = getDateList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context); // 이전 화면으로 돌아감
          },
          icon: Icon(Icons.arrow_back_rounded),
        ),
        // title: Text(
        //   'AD*RESS',
        //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        // ),
        // centerTitle: true,
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
              // style: TextStyle(color: Colors.black),
            ),
          ),
          SizedBox(width: 15),
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () {
              print("✅ 지도보기 버튼 누름");
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
                _effectiveMessages.clear(); // 전송용만 초기화 (채팅 화면은 그대로!)
              });
            },
            icon: Icon(Icons.restart_alt),
          ),
        ],
      ),

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // 키보드 내리기
        },
        behavior: HitTestBehavior.translucent, // 빈 공간도 인식되게
        child: Stack(
          children: [
            Column(
              children: [
                // _buildScheduleArea(),
                Expanded(
                  child: ChatMessageListView(
                    topPadding: 200, // 헤더, 메세지 간격
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
                                      isUser: true,
                                    );
                                    _chatMessages.add(userMessage); // 전체 채팅 출력용
                                    _effectiveMessages.add(userMessage); // 전송용
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

                                        // 📦 선택 결과 받기
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

                                // SizedBox(width: 2),
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
                          FocusScope.of(context).unfocus(); // 🔹 키보드 먼저 내림
                          if (_chatMessages.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("입력을 먼저 해주세요.")),
                            );
                            return;
                          }
                          //로딩 카드 띄우기
                          setState(() {
                            _chatMessages.add(
                              ChatMessage(
                                isUser: false,
                                customWidget: LoadingStyleCard(),
                              ),
                            );
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
                                print("📌 퍼미션 거부 → 서울로 대체");
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
                                print("❗ 현위치 가져오기 실패 → 서울로 대체: $e");
                                _weather = await _fetchDailyWeatherFromLatLon(
                                  _latitude,
                                  _longitude,
                                );
                              }
                            }
                          }

                          final date =
                              _selectedTargetDate ?? _calTargetDate ?? "";
                          if (_weather == null || _weather!.isEmpty) {
                            _ignoreWeather = true;
                          } // 날씨 정보 못가져올 경우 대비
                          else {
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

                              print(
                                "🌧️ $date 날씨\n"
                                "- 상태: $_weatheDescription\n"
                                "- 최저기온: $_temperatureMin°\n"
                                "- 최고기온: $_temperatureMax°\n"
                                "- 강수확률: ${(pop * 100).round()}%\n",
                              );
                            } else {
                              print("❗ 날씨 정보 없음");
                            }
                          }

                          //날씨 반영 X
                          if (_ignoreWeather) {
                            _temperatureMin = null;
                            _temperatureMax = null;
                          }

                          // 사용자 입력 합치기
                          final combinedInput = _effectiveMessages
                              .where((m) => m.isUser && m.text != null)
                              .map((m) => m.text!)
                              .join('\n');

                          final requestData = {
                            "minTemperature": _temperatureMin,
                            "maxTemperature": _temperatureMax,
                            "requirements": combinedInput, // 사용자의 입력
                            "uniqueCoordinationType":
                                coordinationTypeMap[_selectedCoordinationType] ??
                                "", // 영어로 변환
                            "schedule": _selectedEventText ?? "",
                            "necessaryClothesIds":
                                _selectedItems, //옷 id 넣기, null 가능
                            "wardrobeNames": selectedWardrobeIds,
                            "useBasicWardrobe": useBasicWardrobe,
                          };
                          print('📨 $requestData');

                          final loginState = Provider.of<LoginStateManager>(
                            context,
                            listen: false,
                          );

                          final token = loginState.accessToken;
                          if (token == null) {
                            print("❗ 로그인 토큰 없음. 로그인 먼저 필요.");
                            return;
                          }

                          print("🔐 현재 불러온 토큰: $token");
                          print("📨 보내는 정보: $requestData");

                          final responseData = await fetchRecommendation(
                            requestData,
                            'Bearer $token',
                          );
                          print("📨 받는 정보: $responseData");

                          setState(() {
                            _chatMessages.removeWhere(
                              (msg) => msg.customWidget is LoadingStyleCard,
                            );
                            _chatMessages.add(
                              ChatMessage(
                                isUser: false,
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
                        child: Text(
                          "결과보기",
                          // style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 🟫 헤더 영역 (슬라이드 가능하게 상단에 겹침)
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
                  child: Container(
                    color: Colors.black.withOpacity(0.3), // 터치 가능, 시각적 구분
                  ),
                ),
              ),
              Positioned(
                top: _headerOffset, // AppBar 바로 아래
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
                            fontSize: 14,
                            // fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4, // 한 줄에 4개씩
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
