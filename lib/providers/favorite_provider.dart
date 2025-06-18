import 'package:flutter/material.dart';

class FavoriteProvider with ChangeNotifier {
  final List<String> _favoriteCoordinationIds = [];

  List<String> get favorites => _favoriteCoordinationIds;

  bool isFavorite(String id) => _favoriteCoordinationIds.contains(id);

  void addFavorite(String id) {
    if (!_favoriteCoordinationIds.contains(id)) {
      _favoriteCoordinationIds.add(id);
      notifyListeners();
    }
  }

  void removeFavorite(String id) {
    if (_favoriteCoordinationIds.remove(id)) {
      notifyListeners();
    }
  }

  void setFavorites(List<String> ids) {
    _favoriteCoordinationIds.clear();
    _favoriteCoordinationIds.addAll(ids);
    notifyListeners();
  }
}
