import 'package:chat_v0/models/item_model.dart';
import 'package:chat_v0/models/wardrobe_model.dart';
import 'package:chat_v0/providers/item_provider.dart';
import 'package:chat_v0/units/item_field.dart';
import 'package:chat_v0/wardrobe/item_update_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemDetailPage extends StatefulWidget {
  final Item item;
  final Wardrobe wardrobe;

  const ItemDetailPage({super.key, required this.item, required this.wardrobe});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  double front_width = 30;
  double back_width = 90;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = widget.item.getDataMap();
    final type = data['type'];
    final fields = fieldsByType[type] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('아이템 상세'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ItemUpdatePage(
                          item: widget.item,
                          wardrobe: widget.wardrobe,
                        ),
                  ),
                );
                if (result == true && mounted) {
                  Navigator.of(context).pop(true);
                }
              } else if (value == 'delete') {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text("정말 삭제하시겠습니까?"),
                        content: const Text("아이템이 삭제되며 복구할 수 없습니다."),
                        actions: [
                          TextButton(
                            child: const Text("취소"),
                            onPressed: () => Navigator.of(ctx).pop(false),
                          ),
                          ElevatedButton(
                            child: const Text("삭제"),
                            onPressed: () => Navigator.of(ctx).pop(true),
                          ),
                        ],
                      ),
                );

                if (confirmed == true) {
                  final provider = Provider.of<ItemProvider>(
                    context,
                    listen: false,
                  );
                  final success = await provider.deleteItem(widget.item.id);

                  if (success && mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) =>
                              const AlertDialog(content: Text("✅ 삭제되었습니다.")),
                    );
                    await Future.delayed(const Duration(seconds: 1));
                    if (mounted) Navigator.of(context).pop(true);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('❌ 삭제 실패')));
                    }
                  }
                }
              }
            },
            itemBuilder:
                (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('수정')),
                  PopupMenuItem(value: 'delete', child: Text('삭제')),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  data['imageUrl'],
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 스타일, 디테일 먼저 표시
            _buildCombinedStyleField(data),

            // 나머지 필드 표시 (style/detail 제외)
            ...fields
                .where(
                  (field) =>
                      ![
                        'style1',
                        'style2',
                        'style3',
                        'detail1',
                        'detail2',
                        'detail3',
                      ].contains(field),
                )
                .expand(
                  (field) => [
                    _buildDisplayField(field, data, type),
                    const SizedBox(height: 24), // 줄 사이 간격
                  ],
                ),
            _buildCombinedDetailField(data),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedStyleField(Map<String, dynamic> data) {
    final styles =
        [
          data['style1'],
          data['style2'],
          data['style3'],
        ].where((e) => e != null && e.toString().isNotEmpty).toList();

    if (styles.isEmpty) return const SizedBox.shrink();

    final joined = styles.join(', ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: front_width),
        SizedBox(width: back_width, child: Text('스타일')),
        Expanded(child: Text(joined)),
      ],
    );
  }

  Widget _buildCombinedDetailField(Map<String, dynamic> data) {
    final details =
        [
          data['detail1'],
          data['detail2'],
          data['detail3'],
        ].where((e) => e != null && e.toString().isNotEmpty).toList();

    if (details.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: front_width),
        SizedBox(width: back_width, child: Text('디테일')),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                details
                    .map(
                      (d) => Text(
                        d.toString(),
                        style: const TextStyle(height: 1.4),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayField(
    String key,
    Map<String, dynamic> data,
    String? type,
  ) {
    final value = data[key];
    if (value == null || value.toString().isEmpty)
      return const SizedBox.shrink();
    if (key == 'imageUrl') return const SizedBox.shrink();

    final label = labelFor(key);

    // season 필드 (다중 선택)
    if (key == 'season' && value is List) {
      final joined = value.join(', ');
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: front_width),
          SizedBox(width: back_width, child: Text('계절')),
          Expanded(child: Text(joined)),
        ],
      );
    }

    // 줄글 필드
    if (fixedTextFields.contains(key) ||
        (typeSpecificTextFields[type]?.contains(key) ?? false)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: front_width),
          SizedBox(width: back_width, child: Text(label)),
          Expanded(child: Text(value.toString())),
        ],
      );
    }

    // Boolean 필드
    if (typeSpecificBooleanFields[type]?.contains(key) ?? false) {
      final display = (value == true) ? 'YES' : 'NO';
      return Row(
        children: [
          SizedBox(width: front_width),
          SizedBox(width: back_width, child: Text(label)),
          Text(display),
        ],
      );
    }

    // 일반 필드
    return Row(
      children: [
        SizedBox(width: front_width),
        SizedBox(width: back_width, child: Text(label)),
        Expanded(child: Text(value.toString())),
      ],
    );
  }
}
