import 'package:flutter/material.dart';

/// 選手一覧の絞り込み(学年・ポジション・並び順)バー。
class PlayerFilterBar extends StatelessWidget {
  const PlayerFilterBar({
    super.key,
    required this.grade,
    required this.position,
    required this.sortType,
    required this.onGradeChanged,
    required this.onPositionChanged,
    required this.onSortChanged,
  });

  final String grade;
  final String position;
  final String sortType;
  final ValueChanged<String> onGradeChanged;
  final ValueChanged<String> onPositionChanged;
  final ValueChanged<String> onSortChanged;

  static const grades = ['全員', '1年', '2年', '3年', '4年', '社会人', '未設定'];
  static const positions = ['全員', 'S', 'WS', 'MB', 'OP', 'L', '未設定'];
  static const sortTypes = ['背番号', '学年', '名前'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  label: '学年',
                  value: grade,
                  items: grades,
                  onChanged: onGradeChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown(
                  label: 'ポジション',
                  value: position,
                  items: positions,
                  onChanged: onPositionChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _dropdown(
            label: '並び順',
            value: sortType,
            items: sortTypes,
            onChanged: onSortChanged,
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
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