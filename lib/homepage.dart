import 'package:chat_v0/community/community_main_page.dart';
import 'package:chat_v0/liked/liked_recommendation_page.dart';
import 'package:chat_v0/menu/layout.dart';
import 'package:chat_v0/recommendation/get_data.dart';
import 'package:chat_v0/wardrobe/wardrobe_main_page.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<WardrobeMainPageState> _wardrobeKey = GlobalKey();
  late List<Widget> _pages;

  // 각 텝의 title 👔❤️
  final List<String> _appBarTitles = ['옷장', '즐겨찾기', '커뮤니티'];

  @override
  void initState() {
    super.initState();
    _pages = [
      WardrobeMainPage(key: _wardrobeKey),
      LikedRecommendationsPage(),
      CommunityPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0, // 스크롤해도 절대 변화 없음
        // backgroundColor: Colors.white12, // 🔒 색 고정
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            showCustomMenuDrawer(context);
          },
          icon: Icon(Icons.menu),
        ),
        title: Text(
          _appBarTitles[_selectedIndex],
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        // centerTitle: true,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: Icon(Icons.create_new_folder),
              onPressed: () {
                _wardrobeKey.currentState?.showCreateWardrobeDialog(); // ✅ 호출!
              },
            ),
          TextButton(
            onPressed: () {
              // 👉 추천받기 화면으로 이동 (하단 탭 없이)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecommendationPage()),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: const Color.fromARGB(255, 207, 237, 207),
            ),
            child: Text('추천받기 🔮'),
          ),
          SizedBox(width: 12),
        ],
      ),
      body: _pages[_selectedIndex], // 선택된 페이지 표시
      bottomNavigationBar: BottomNavigationBar(
        // backgroundColor: ColorScheme.inver,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color.fromARGB(255, 10, 59, 55), // 선택된 아이템 색
        unselectedItemColor: Colors.grey[500], // 선택 안 된 아이템 색
        selectedFontSize: 12,
        unselectedFontSize: 10,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 22),
            label: '옷장',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite, size: 22),
            label: '즐겨찾기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 22),
            label: '커뮤니티',
          ),
        ],
      ),
    );
  }
}
