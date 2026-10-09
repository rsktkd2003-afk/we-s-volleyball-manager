import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'cork_board_background.dart';
import 'pinned_paper_card.dart';

/// コルクボードに「準備中」の紙を1枚貼ったプレースホルダー画面。
/// ホーム・練習タブの本実装までの仮表示に使う。Firestore にはアクセスしない。
class ClubBoardPlaceholder extends StatelessWidget {
  const ClubBoardPlaceholder({
    super.key,
    required this.title,
    required this.icon,
    required this.headline,
    required this.message,
    required this.plannedItems,
  });

  /// ボード見出し(例: WE'S CLUB BOARD)。
  final String title;
  final IconData icon;

  /// 紙に書く見出し。
  final String headline;
  final String message;

  /// 今後この画面に配置する予定の内容。
  final List<String> plannedItems;

  @override
  Widget build(BuildContext context) {
    return CorkBoardBackground(
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BoardHeading(title: title),
                  const SizedBox(height: 12),
                  PinnedPaperCard(
                    margin: EdgeInsets.zero,
                    showTape: true,
                    child: _PlaceholderNote(
                      icon: icon,
                      headline: headline,
                      message: message,
                      plannedItems: plannedItems,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardHeading extends StatelessWidget {
  const _BoardHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    // コルク地の上でも読めるよう、見出しは紙の帯に載せる。
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            offset: Offset(0, 3),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "WE'S VOLLEYBALL CLUB",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(width: 56, height: 4, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _PlaceholderNote extends StatelessWidget {
  const _PlaceholderNote({
    required this.icon,
    required this.headline,
    required this.message,
    required this.plannedItems,
  });

  final IconData icon;
  final String headline;
  final String message;
  final List<String> plannedItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                headline,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '今後ここに掲示する予定',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in plannedItems)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.push_pin_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
