import 'package:chat_v0/community/comunity_card.dart';
import 'package:flutter/material.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dummyPosts = [
      {
        "imageUrl": "https://picsum.photos/id/821/600/400",
        "userId": "daily_casual",
        "userProfile": "https://picsum.photos/id/1005/40/40",
        "title": "오늘의 출근룩",
        "hashtags": "#오피스룩 #심플하게 #블랙앤화이트",
        "description": "간단한 출근용 코디! 블랙 자켓에 화이트 셔츠, 그리고 슬랙스로 마무리했습니다. 어떤가요?",
      },
      {
        "imageUrl": "https://picsum.photos/id/823/400/400",
        "userId": "weekend_chill",
        "userProfile": "https://picsum.photos/id/1012/40/40",
        "title": "숲 속 스트릿 감성 🌲📸",
        "hashtags": "#스트릿룩 #아웃도어 #레드비니 #빈티지무드",
        "description":
            "빨간 비니와 청셔츠, 검정 이너의 조합은 언제나 정답. 자연 배경과 어우러진 빈티지 스트릿 무드, 카메라 한 손에 들고 숲 속을 거니는 느낌을 담았어요. 요즘은 이런 내추럴한 스타일에 빠져있습니다.",
      },
      {
        "imageUrl": "https://picsum.photos/id/777/600/400",
        "userId": "colorful_day",
        "userProfile": "https://picsum.photos/id/1009/40/40",
        "title": "잔잔하고 매력있게",
        "hashtags": "#감성룩 #시스루스커트 #노을빛",
        "description":
            "흰 민소매와 시스루 스커트가 노을빛과 어우러지며 자연 속에서 은은한 분위기를 만들어줘요. 물결 따라 흐르는 강과 저 너머의 나무들이 조용한 위로처럼 느껴졌던 순간. 이런 스타일, 어때요? ",
      },
      {
        "imageUrl": "https://picsum.photos/id/656/600/400",
        "userId": "simple_dresser",
        "userProfile": "https://picsum.photos/id/1016/40/40",
        "title": "심플한 흰 원피스",
        "hashtags": "#미니멀 #화이트 #원피스",
        "description": "흰 원피스 하나면 모든 게 해결되는 날. 깔끔하게 연출할 수 있어 좋아요!",
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: dummyPosts.length,
      itemBuilder: (context, index) {
        final post = dummyPosts[index];
        return CommunityPostCard(
          imageUrl: post['imageUrl']!,
          userId: post['userId']!,
          userProfile: post['userProfile']!,
          title: post['title']!,
          hashtags: post['hashtags']!,
          description: post['description']!,
        );
      },
    );
  }
}
