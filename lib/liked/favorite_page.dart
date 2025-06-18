import 'package:chat_v0/liked/liked_style_card.dart';
import 'package:chat_v0/providers/favorite_provider.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  Map<String, dynamic> favoriteStyles = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final loginStateManager = Provider.of<LoginStateManager>(
      context,
      listen: false,
    );
    final favoriteProvider = Provider.of<FavoriteProvider>(
      context,
      listen: false,
    );

    final List<Map<String, dynamic>> data = await getFavoriteCoordinations(
      loginStateManager: loginStateManager,
    );

    final Map<String, dynamic> mapped = {
      for (var style in data) style['coordinationId']: style,
    };

    favoriteProvider.setFavorites(mapped.keys.toList());

    if (!mounted) return;

    setState(() {
      favoriteStyles = mapped;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : favoriteStyles.isEmpty
              ? const Center(child: Text('찜한 스타일이 없습니다.'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(12.0),
                child: StyleLikedView(
                  responseData: favoriteStyles,
                  isLikedView: true,
                ),
              ),
    );
  }
}
