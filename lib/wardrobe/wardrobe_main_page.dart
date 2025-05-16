import 'dart:io';
import 'package:chat_v0/providers/wardobe_provider.dart';
import 'package:chat_v0/wardrobe/item_register_page.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/wardrobe_model.dart';
import 'wardrobe_details.dart';

class WardrobeMainPage extends StatefulWidget {
  const WardrobeMainPage({super.key});

  @override
  State<WardrobeMainPage> createState() => WardrobeMainPageState();
}

class WardrobeMainPageState extends State<WardrobeMainPage> {
  bool _showImageOptions = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<WardrobeProvider>(context, listen: false).fetchWardrobes();
    });
  }

  void showCreateWardrobeDialog() {
    String wardrobeName = '';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('옷장 만들기'),
            content: TextField(
              onChanged: (value) => wardrobeName = value,
              decoration: const InputDecoration(hintText: "옷장 이름 입력"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (wardrobeName.trim().isNotEmpty) {
                    Provider.of<WardrobeProvider>(
                      context,
                      listen: false,
                    ).addWardrobe(wardrobeName);
                    Navigator.pop(context);
                  }
                },
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  void _showRenameDialog(Wardrobe wardrobe) {
    String newName = wardrobe.name;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('이름 변경'),
            content: TextField(
              decoration: const InputDecoration(hintText: '새 이름 입력'),
              onChanged: (value) => newName = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  Provider.of<WardrobeProvider>(
                    context,
                    listen: false,
                  ).renameWardrobe(wardrobe.id, newName);
                  Navigator.pop(context);
                },
                child: const Text('변경'),
              ),
            ],
          ),
    );
  }

  void _confirmDelete(Wardrobe wardrobe) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('정말 삭제하시겠어요?'),
            content: Text('"${wardrobe.name}" 옷장이 삭제됩니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  Provider.of<WardrobeProvider>(
                    context,
                    listen: false,
                  ).deleteWardrobe(wardrobe.id);
                  Navigator.pop(context);
                },
                child: const Text('삭제'),
              ),
            ],
          ),
    );
  }

  void _navigateToDetail(Wardrobe wardrobe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => WardrobeDetailPage(
              wardrobeName: wardrobe.name,
              wardrobeId: wardrobe.id,
            ),
      ),
    );
  }

  void _toggleImageOptions() {
    setState(() => _showImageOptions = !_showImageOptions);
  }

  Future<File?> _pickAndCropImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return null;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 80,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: '이미지 자르기', lockAspectRatio: false),
        IOSUiSettings(title: '이미지 자르기'),
      ],
    );

    if (croppedFile == null) return null;

    final File image = File(croppedFile.path);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemRegisterPage(image: image)),
    );

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final wardrobeList = Provider.of<WardrobeProvider>(context).wardrobes;
    final int crossAxisCount = 2;
    final bool isOdd = wardrobeList.length % crossAxisCount != 0;

    final List<Widget> gridItems =
        wardrobeList.map<Widget>((wardrobe) {
          return GestureDetector(
            onTap: () => _navigateToDetail(wardrobe),
            child: Card(
              child: Stack(
                children: [
                  Center(child: Text(wardrobe.name)),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showRenameDialog(wardrobe);
                        } else if (value == 'delete') {
                          _confirmDelete(wardrobe);
                        }
                      },
                      itemBuilder:
                          (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('이름 변경')),
                            PopupMenuItem(value: 'delete', child: Text('삭제')),
                          ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList();

    if (isOdd) gridItems.add(const SizedBox());
    gridItems.add(const SizedBox(height: 50));

    return Scaffold(
      body: GridView.count(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        children: gridItems,
      ),
      floatingActionButton: Stack(
        children: [
          if (_showImageOptions)
            Positioned(
              bottom: 68,
              left: 14,
              child: Row(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'gallery',
                    onPressed: () => _pickAndCropImage(ImageSource.gallery),
                    backgroundColor: Colors.white,
                    elevation: 2,
                    child: const Icon(Icons.photo_library, color: Colors.black),
                  ),
                  const SizedBox(width: 5),
                  FloatingActionButton.small(
                    heroTag: 'camera',
                    onPressed: () => _pickAndCropImage(ImageSource.camera),
                    backgroundColor: Colors.white,
                    elevation: 2,
                    child: const Icon(Icons.camera_alt, color: Colors.black),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: 16,
            left: 0,
            // right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _toggleImageOptions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 70, 42),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('옷 등록'),
                      SizedBox(width: 6),
                      Icon(Icons.add),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
