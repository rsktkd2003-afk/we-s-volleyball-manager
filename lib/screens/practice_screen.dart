import 'package:flutter/material.dart';

import '../widgets/club_board_placeholder.dart';

/// 練習タブ。Phase 1 では練習案機能のプレースホルダーのみ表示する。
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClubBoardPlaceholder(
      title: 'PRACTICE IDEAS',
      icon: Icons.sports_volleyball_outlined,
      headline: '練習案ボードを準備中です',
      message: 'やってみたい練習をメンバー全員で出し合い、'
          '「これやりたい」で投票できる掲示板をここに用意する予定です。',
      plannedItems: [
        '練習案の投稿',
        '「これやりたい」投票',
        '人気順・新着順の表示',
        '実施済みの記録',
      ],
    );
  }
}
