import 'package:chat_v0/community/post_detail_page.dart';
import 'package:chat_v0/providers/login_state_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';

class CommunityMainPage extends StatefulWidget {
  const CommunityMainPage({super.key});

  @override
  State<CommunityMainPage> createState() => CommunityMainPageState();
}

class CommunityMainPageState extends State<CommunityMainPage>
    with AutomaticKeepAliveClientMixin<CommunityMainPage> {
  final List<String> fakeNames = [
    'mintyfox',
    'coolcat',
    'sunnybee',
    'nightowl',
    'rainyday',
    'greenleaf',
  ];

  String getFakeNameByIndex(int index) {
    return fakeNames[index % fakeNames.length];
  }

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _sortMode = 'latest';
  int _page = 0;
  final int _size = 10;
  bool _hasMore = true;
  bool _isFetching = false;
  bool _showLoadingIndicator = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<CommunityProvider>(context, listen: false);
      if (provider.posts.isEmpty || _page == 0) {
        _fetchPosts(reset: true);
      } else {}
    });

    _scrollController.addListener(_scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final communityProvider = Provider.of<CommunityProvider>(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 5, 0, 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      setState(() {
                        _sortMode = value;
                      });
                      _fetchPosts(reset: true);
                    },
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            height: 40,
                            value: 'popular',
                            child: Text('인기순'),
                          ),
                          PopupMenuItem(
                            height: 40,
                            value: 'latest',
                            child: Text('최신순'),
                          ),
                        ],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _sortMode == 'popular' ? '인기순' : '최신순',
                            style: TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (_) {
                  final posts = communityProvider.posts;
                  final isLoading = communityProvider.isLoading;
                  final loginUsername =
                      context.read<LoginStateManager>().username;

                  if (isLoading && posts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount:
                        communityProvider.posts.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < communityProvider.posts.length) {
                        final post = communityProvider.posts[index];
                        final formattedDate = intl.DateFormat(
                          'yyyy. MM. dd a h시',
                        ).format(post.createdAt.toLocal());
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 12.0,
                          ),
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) =>
                                          PostDetailScreen(postId: post.postId),
                                ),
                              );
                              if (result == true) {
                                // 게시글 삭제됨
                                _fetchPosts(reset: true);
                              } else if (result is Map) {
                                // 댓글 수 또는 좋아요 상태가 바뀜
                                setState(() {
                                  post.commentCount =
                                      result['commentCount'] ??
                                      post.commentCount;
                                  post.likeCount =
                                      result['likeCount'] ?? post.likeCount;
                                });
                              } else {
                                // 아무런 변화 없음
                              }
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                (post.photoUrls != null &&
                                        post.photoUrls!.isNotEmpty)
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        post.photoUrls!.first,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.image_not_supported,
                                      size: 100,
                                    ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          if (loginUsername == post.username) {
                                            Navigator.pushNamed(
                                              context,
                                              '/myProfile',
                                            );
                                          } else {
                                            Navigator.pushNamed(
                                              context,
                                              '/userProfile',
                                              arguments: post.username,
                                            );
                                          }
                                        },
                                        child: Text(
                                          post.username,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      post.hasContent
                                          ? Text(
                                            post.content,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                          : const SizedBox(height: 16),
                                      const SizedBox(height: 4),
                                      post.hasHashtags
                                          ? Text.rich(
                                            TextSpan(
                                              children: [
                                                ...post.hashtags
                                                    .take(10)
                                                    .map(
                                                      (tag) => TextSpan(
                                                        text: '$tag ',
                                                        style: const TextStyle(
                                                          color: Colors.blue,
                                                        ),
                                                      ),
                                                    ),
                                                if (post.hashtags.length > 10)
                                                  const TextSpan(
                                                    text: '...',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                          : const SizedBox(height: 16),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.favorite_border,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text('${post.likeCount}'),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.comment, size: 16),
                                          const SizedBox(width: 4),
                                          Text('${post.commentCount}'),
                                          const SizedBox(width: 50),
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (_hasMore) {
                        return _showLoadingIndicator
                            ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                            : const SizedBox.shrink();
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isFetching &&
        _hasMore) {
      _fetchPosts();
    }
  }

  Future<void> _fetchPosts({bool reset = false}) async {
    if (_isFetching) return;

    final communityProvider = Provider.of<CommunityProvider>(
      context,
      listen: false,
    );

    _isFetching = true;

    if (mounted) {
      setState(() => _showLoadingIndicator = true);
    }

    final int nextPage = reset ? 0 : _page;

    final int fetchedCount = await communityProvider.fetchPosts(
      sort: _sortMode,
      page: nextPage,
      size: _size,
      append: !reset,
      reset: reset,
    );

    if (mounted) {
      setState(() {
        if (reset) {
          _page = 1;
          _hasMore = true;
        } else {
          _page++;
        }

        if (fetchedCount < _size) {
          _hasMore = false;
        }

        _showLoadingIndicator = false;
      });
    }

    _isFetching = false;
  }

  void refreshPosts() => _fetchPosts(reset: true);

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
