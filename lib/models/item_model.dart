class Item {
  final String id;
  final String userId;
  final String wardrobeId;
  final String imageUrl;
  final String type;
  final String? color;
  final String? style1;
  final String? style2;
  final String? style3;
  final String? fit;
  final List<String>? season;
  final String? tpo;
  final String? detail1;
  final String? detail2;
  final String? detail3;
  final String? print;
  final String? pattern;
  final String? category;
  final String? topLength;
  final String? sleeveLength;
  final String? bottomLength;
  final String? pantsFit;
  final String? skirtLength;
  final String? skirtFit;
  final String? skirtType;
  final bool? isSeeThrough;
  final bool? isSimple;
  final bool? isTopRequired;
  final String? saturation;
  final String? brightness;

  Item({
    required this.id,
    required this.userId,
    required this.wardrobeId,
    required this.imageUrl,
    required this.type,
    this.color,
    this.style1,
    this.style2,
    this.style3,
    this.fit,
    this.season,
    this.tpo,
    this.detail1,
    this.detail2,
    this.detail3,
    this.print,
    this.pattern,
    this.category,
    this.topLength,
    this.sleeveLength,
    this.bottomLength,
    this.pantsFit,
    this.skirtLength,
    this.skirtFit,
    this.skirtType,
    this.isSeeThrough,
    this.isSimple,
    this.isTopRequired,
    this.saturation,
    this.brightness,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      wardrobeId: json['wardrobeId'] ?? '',
      imageUrl: json['imageUrl'] ?? '', // ✅ 요 부분!
      type: json['type'] ?? '',
      color: json['color'],
      style1: json['style1'],
      style2: json['style2'],
      style3: json['style3'],
      fit: json['fit'],
      season:
          (json['season'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      tpo: json['tpo'],
      detail1: json['detail1'],
      detail2: json['detail2'],
      detail3: json['detail3'],
      print: json['print'],
      pattern: json['pattern'],
      category: json['category'],
      topLength: json['topLength'],
      sleeveLength: json['sleeveLength'],
      bottomLength: json['bottomLength'],
      pantsFit: json['pantsFit'],
      skirtLength: json['skirtLength'],
      skirtFit: json['skirtFit'],
      skirtType: json['skirtType'],
      isSeeThrough: json['isSeeThrough'],
      isSimple: json['isSimple'],
      isTopRequired: json['isTopRequired'],
      saturation: json['saturation'],
      brightness: json['brightness'],
    );
  }
  //데이터 수집 용
  Map<String, dynamic> getDataMap() {
    return {
      'id': id,
      'userId': userId,
      'wardrobeId': wardrobeId,
      'imageUrl': imageUrl,
      'type': type,
      'color': color,
      'style1': style1,
      'style2': style2,
      'style3': style3,
      'fit': fit,
      'season': season,
      'tpo': tpo,
      'detail1': detail1,
      'detail2': detail2,
      'detail3': detail3,
      'print': print,
      'pattern': pattern,
      'category': category,
      'topLength': topLength,
      'sleeveLength': sleeveLength,
      'bottomLength': bottomLength,
      'pantsFit': pantsFit,
      'skirtLength': skirtLength,
      'skirtFit': skirtFit,
      'skirtType': skirtType,
      'isSeeThrough': isSeeThrough,
      'isSimple': isSimple,
      'isTopRequired': isTopRequired,
      'saturation': saturation,
      'brightness': brightness,
    };
  }

  //데이터 전송 용
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'wardrobeId': wardrobeId,
      'imageUrl': imageUrl,
      'type': type,
      'color': color,
      'style1': style1,
      'style2': style2,
      'style3': style3,
      'fit': fit,
      'season': season,
      'tpo': tpo,
      'detail1': detail1,
      'detail2': detail2,
      'detail3': detail3,
      'print': print,
      'pattern': pattern,
      'category': category,
      'topLength': topLength,
      'sleeveLength': sleeveLength,
      'bottomLength': bottomLength,
      'pantsFit': pantsFit,
      'skirtLength': skirtLength,
      'skirtFit': skirtFit,
      'skirtType': skirtType,
      'isSeeThrough': isSeeThrough,
      'isSimple': isSimple,
      'isTopRequired': isTopRequired,
      'saturation': saturation,
      'brightness': brightness,
    };
  }
}
