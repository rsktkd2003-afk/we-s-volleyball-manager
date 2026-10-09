import 'package:flutter/material.dart';

import '../widgets/club_board_placeholder.dart';

/// ホームタブ。Phase 1 では Dashboard のプレースホルダーのみ表示する。
/// (従来の選手一覧は MembersScreen、予定は ScheduleScreen へ移動)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ClubBoardPlaceholder(
      title: "WE'S CLUB BOARD",
      icon: Icons.dashboard_outlined,
      headline: 'ダッシュボードを準備中です',
      message: 'チームの「今」をひと目で確認できる掲示板を、ここに用意する予定です。'
          '予定・出欠・メンバーは、ナビゲーションの各タブから利用できます。',
      plannedItems: [
        '次回の活動と自分の出欠',
        '参加・遅刻・欠席の人数',
        '未回答の予定',
        '重要なお知らせ',
        'やりたい練習の上位',
      ],
    );
  }
}
