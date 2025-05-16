import 'package:chat_v0/recommendation/style_card.dart';
import 'package:flutter/material.dart';

class LikedRecommendationsPage extends StatefulWidget {
  const LikedRecommendationsPage({super.key});

  @override
  State<LikedRecommendationsPage> createState() =>
      _LikedRecommendationsPageState();
}

class _LikedRecommendationsPageState extends State<LikedRecommendationsPage> {
  Map<String, dynamic> likedData = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await loadAllLikedRecommendations();
    setState(() {
      likedData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          likedData.isEmpty
              ? Center(child: Text("아직 찜한 스타일이 없어요."))
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: StyleRecommendationView(
                  responseData: likedData,
                  isLikedView: true,
                ),
              ),
    );
  }
}
