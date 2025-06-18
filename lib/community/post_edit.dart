import 'dart:convert';
import 'dart:io';
import 'package:chat_v0/models/post_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/login_state_manager.dart';

class PostEditScreen extends StatefulWidget {
  final Post post;
  const PostEditScreen({super.key, required this.post});

  @override
  State<PostEditScreen> createState() => _PostEditScreenState();
}

class _PostEditScreenState extends State<PostEditScreen> {
  late TextEditingController _contentController;
  late TextEditingController _hashtagController;
  final List<File> _newImages = [];
  late List<String> _existingImageUrls;
  final Set<String> _deletedUrls = {};

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.post.content);
    _hashtagController = TextEditingController(
      text: widget.post.hashtags.join(' '),
    );
    _existingImageUrls = List.from(widget.post.photoUrls ?? []);
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _newImages.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _submitEdit() async {
    final authToken = context.read<LoginStateManager>().accessToken;
    final backendIp = dotenv.env['BACKEND_IP_WAR'] ?? 'default_ip_address';

    if (authToken == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
      return;
    }

    final uri = Uri.parse(
      'http://$backendIp:8081/api/posts/${widget.post.postId}/update-with-images',
    );
    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $authToken';
    request.headers['Content-Type'] = 'multipart/form-data';

    for (final file in _newImages) {
      final multipart = await http.MultipartFile.fromPath('images', file.path);
      request.files.add(multipart);
    }

    final keepUrls =
        _existingImageUrls.where((url) => !_deletedUrls.contains(url)).toList();

    final postPayload = {
      'content': _contentController.text,
      'hashtags':
          _hashtagController.text
              .split(RegExp(r'\\s+'))
              .where((tag) => tag.startsWith('#'))
              .toList(),
    };

    request.fields['keepImageUrls'] = jsonEncode(keepUrls);
    request.fields['post'] = jsonEncode(postPayload);

    final response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('수정 완료')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('수정 실패: ${response.statusCode}')));
    }
  }

  void _removeExistingImage(String url) {
    setState(() {
      _deletedUrls.add(url);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 수정'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: '내용'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _hashtagController,
                decoration: const InputDecoration(labelText: '해시태그 (예: #tag)'),
              ),
              const SizedBox(height: 10),
              const Text('기존 이미지:'),
              Wrap(
                spacing: 8,
                children:
                    _existingImageUrls
                        .where((url) => !_deletedUrls.contains(url))
                        .map(
                          (url) => Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Image.network(
                                url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeExistingImage(url),
                              ),
                            ],
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 10),
              const Text('새 이미지 추가:'),
              Wrap(
                spacing: 8,
                children:
                    _newImages
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
                    onPressed: _submitEdit,
                    child: const Text('수정 완료'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
