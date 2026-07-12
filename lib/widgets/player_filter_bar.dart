import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pin_badge.dart';

/// 選手一覧の絞り込み(検索・学年・ポジション・並び順)パネル。
class PlayerFilterBar extends StatefulWidget {
  const PlayerFilterBar({
    super.key,
    required this.searchQuery,
    required this.grade,
    required this.position,
    required this.sortType,
    required this.onSearchChanged,
    required this.onGradeChanged,
    required this.onPositionChanged,
    required this.onSortChanged,
  });

  final String searchQuery;
  final String grade;
  final String position;
  final String sortType;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onGradeChanged;
  final ValueChanged<String> onPositionChanged;
  final ValueChanged<String> onSortChanged;

  static const grades = ['全員', '1年', '2年', '3年', '4年', '社会人', '未設定'];
  static const positions = ['全員', 'S', 'WS', 'MB', 'OP', 'L', '未設定'];
  static const sortTypes = ['背番号', '学年', '名前'];

  @override
  State<PlayerFilterBar> createState() => _PlayerFilterBarState();
}

class _PlayerFilterBarState extends State<PlayerFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 4),
                color: Color(0x26000000),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FILTER & SEARCH',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                onChanged: widget.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search player...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFDDD8CE)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _FieldLabel('GRADE'),
              const SizedBox(height: 6),
              _dropdown(
                value: widget.grade,
                items: PlayerFilterBar.grades,
                onChanged: widget.onGradeChanged,
              ),
              const SizedBox(height: 16),
              _FieldLabel('POSITION'),
              const SizedBox(height: 6),
              _dropdown(
                value: widget.position,
                items: PlayerFilterBar.positions,
                onChanged: widget.onPositionChanged,
              ),
              const SizedBox(height: 16),
              _FieldLabel('SORT'),
              const SizedBox(height: 6),
              _dropdown(
                value: widget.sortType,
                items: PlayerFilterBar.sortTypes,
                onChanged: widget.onSortChanged,
              ),
            ],
          ),
        ),
        const Positioned(
          top: -12,
          left: 0,
          right: 0,
          child: Center(child: PinBadge(size: 20)),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFDDD8CE)),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }
}
