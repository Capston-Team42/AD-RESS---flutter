import 'package:chat_v0/models/item_model.dart';
import 'package:chat_v0/providers/item_provider.dart';
import 'package:chat_v0/providers/wardobe_provider.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

class SelectItemBottomSheet extends StatefulWidget {
  const SelectItemBottomSheet({super.key});

  @override
  State<SelectItemBottomSheet> createState() => _SelectItemBottomSheetState();
}

class _SelectItemBottomSheetState extends State<SelectItemBottomSheet> {
  double _sheetFraction = 0.5; // 0.3 ~ 0.9 사이
  bool _isWardrobeExpanded = false;
  String _selectedWardrobeName = '전체 의류';
  String? _selectedWardrobeId; // null이면 전체 의류
  List<Item> _filteredItems = [];
  final List<Item> _selectedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final wardrobeProvider = Provider.of<WardrobeProvider>(
      context,
      listen: false,
    );

    setState(() => _isLoading = true);
    if (_selectedWardrobeId == null || _selectedWardrobeId == 'all') {
      // 전체 아이템
      await itemProvider.fetchAllItems();
      _filteredItems = itemProvider.allItems;
    } else {
      // 옷장별 아이템
      _filteredItems = await wardrobeProvider.fetchItemsByWardrobe(
        _selectedWardrobeId!,
      );
    }
    setState(() => _isLoading = false);
  }

  void _toggleItemSelection(Item item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        if (_selectedItems.isEmpty) {
          _selectedItems.add(item);
        } else {
          showSimpleNotification(
            const Text("최대 1개만 선택할 수 있어요."),
            background: Color.fromARGB(255, 13, 52, 3),
          );
        }
      }
    });
  }

  void _removeSelectedItem(Item item) {
    setState(() {
      _selectedItems.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final wardrobes = Provider.of<WardrobeProvider>(context).wardrobes;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: screenHeight * _sheetFraction,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _sheetFraction -= details.primaryDelta! / screenHeight;
                _sheetFraction = _sheetFraction.clamp(0.3, 0.9);
              });
            },
            child: Container(
              height: 6,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap:
                () =>
                    setState(() => _isWardrobeExpanded = !_isWardrobeExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedWardrobeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  _isWardrobeExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ],
            ),
          ),
          if (_isWardrobeExpanded)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildWardrobeChip('전체 의류', null),
                  ...wardrobes.map(
                    (w) => _buildWardrobeChip(w.name ?? '이름 없음', w.id),
                  ),
                ],
              ),
            ),
          const Divider(),
          if (_selectedItems.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _selectedItems.length,
                itemBuilder: (context, index) {
                  final item = _selectedItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removeSelectedItem(item),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                padding: const EdgeInsets.all(12),
                children:
                    _filteredItems.map((item) {
                      final isSelected = _selectedItems.contains(item);
                      return GestureDetector(
                        onTap: () => _toggleItemSelection(item),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black.withOpacity(
                                    0.7,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _selectedItems);
              },
              child: const Text('선택 완료'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWardrobeChip(String name, String? id) {
    final isSelected = _selectedWardrobeId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(name),
        selected: isSelected,
        onSelected:
            (_) => setState(() {
              _selectedWardrobeName = name;
              _selectedWardrobeId = id;
              _isWardrobeExpanded = false;
              _loadItems();
            }),
      ),
    );
  }
}
