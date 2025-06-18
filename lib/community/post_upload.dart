import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import '../providers/login_state_manager.dart';

class PostUploadScreen extends StatefulWidget {
  const PostUploadScreen({super.key});

  @override
  State<PostUploadScreen> createState() => _PostUploadScreenState();
}

class _PostUploadScreenState extends State<PostUploadScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final List<File> _images = [];

  // 이미지 압축 함수
  Future<File> compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(
      tempDir.path,
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final XFile? compressedXFile =
        await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: 70,
          format: CompressFormat.jpeg,
        );

    if (compressedXFile != null) {
      return File(compressedXFile.path);
    } else {
      return file;
    }
  }

  // 이미지 선택 + 압축
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      List<File> compressedFiles = [];
      for (final image in picked) {
        final file = File(image.path);
        final compressed = await compressImage(file);
        compressedFiles.add(compressed);
      }

      setState(() {
        _images.addAll(compressedFiles);
      });
    }
  }

  // 게시글 업로드
  Future<void> _uploadPost() async {
    final loginState = context.read<LoginStateManager>();
    final authToken = loginState.accessToken;
    final username = loginState.userId;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';

    if (authToken == null || username == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
      return;
    }

    final uri = Uri.parse('http://$backendIp:8081/api/posts/upload');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $authToken';
    request.headers['Content-Type'] = 'multipart/form-data';

    for (final file in _images) {
      final multipart = await http.MultipartFile.fromPath('images', file.path);
      request.files.add(multipart);
    }

    final postPayload = {
      'username': username,
      'content': _contentController.text,
      'hashtags':
          _hashtagController.text
              .split(RegExp(r'\s+'))
              .where((tag) => tag.startsWith('#'))
              .toList(),
    };

    request.fields['post'] = jsonEncode(postPayload);

    final response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('업로드 완료')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('업로드 실패: ${response.statusCode}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('게시글 작성'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: '내용'),
              maxLines: 5,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _hashtagController,
              decoration: const InputDecoration(
                labelText: '해시태그 (예: #test #jwt)',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children:
                  _images
                      .map(
                        (file) => Image.file(
                          file,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.image),
                  label: const Text('이미지 선택'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _uploadPost,
                  child: const Text('업로드'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
