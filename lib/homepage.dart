import 'package:chat_v0/community/community_main_page.dart';
import 'package:chat_v0/community/post_upload.dart';
import 'package:chat_v0/liked/favorite_page.dart';
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
  final GlobalKey<CommunityMainPageState> _communityKey =
      GlobalKey<CommunityMainPageState>();
  late List<Widget> _pages;

  // 각 텝의 title
  final List<String> _appBarTitles = ['옷장', '즐겨찾기', '커뮤니티'];

  @override
  void initState() {
    super.initState();
    _pages = [
      WardrobeMainPage(key: _wardrobeKey),
      FavoritePage(),
      CommunityMainPage(key: _communityKey),
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
        scrolledUnderElevation: 0,
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
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: Icon(Icons.create_new_folder),
              onPressed: () {
                _wardrobeKey.currentState?.showCreateWardrobeDialog();
              },
            ),
          if (_selectedIndex == 2)
            IconButton(
              icon: Icon(Icons.mode_edit_rounded),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostUploadScreen()),
                );
                if (result == true) {
                  _communityKey.currentState?.refreshPosts();
                }
              },
            ),
          TextButton(
            onPressed: () {
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
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Color.fromARGB(255, 10, 59, 55),
        unselectedItemColor: Colors.grey[500],
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
