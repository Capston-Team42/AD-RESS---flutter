import 'package:chat_v0/models/item_model.dart';
import 'package:chat_v0/models/wardrobe_model.dart';
import 'package:chat_v0/providers/wardobe_provider.dart';
import 'package:chat_v0/wardrobe/item_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

class WardrobeDetailPage extends StatefulWidget {
  final String wardrobeName;
  final String wardrobeId;

  const WardrobeDetailPage({
    super.key,
    required this.wardrobeName,
    required this.wardrobeId,
  });

  @override
  State<WardrobeDetailPage> createState() => _WardrobeDetailPageState();
}

class _WardrobeDetailPageState extends State<WardrobeDetailPage> {
  final backendIp = dotenv.env['BACKEND_IP'] ?? 'default_ip_address';
  List<Item> items = [];
  bool _isLoading = true;

  Future<void> _loadItems() async {
    final provider = Provider.of<WardrobeProvider>(context, listen: false);
    final result = await provider.fetchItemsByWardrobe(widget.wardrobeId);
    if (!mounted) return;
    setState(() {
      items = result;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.wardrobeName)),
      body:
          _isLoading
              ? const Center()
              : items.isEmpty
              ? Center(child: Text('옷장이 비었습니다.'))
              : GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final wardrobe = Wardrobe(
                    id: widget.wardrobeId,
                    name: widget.wardrobeName,
                  );
                  print("🖼️ imageUrl: ${item.imageUrl}"); //디버깅
                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ItemDetailPage(
                                item: item,
                                wardrobe: wardrobe,
                              ),
                        ),
                      );
                      if (result == true && mounted) {
                        await _loadItems();
                      }
                    },
                    child: Card(
                      clipBehavior: Clip.antiAlias, // 이미지가 카드 영역을 넘지 않도록 잘라줌
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Image.network(
                          item.imageUrl,
                          height: 150, // 세로 길이 제한
                          width: double.infinity, // 가로는 꽉 채우되
                          fit: BoxFit.contain, // 비율 유지하며 중앙에 배치
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
