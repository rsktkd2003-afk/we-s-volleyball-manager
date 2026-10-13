import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pin_badge.dart';

/// 絞り込みパネルの配置。
enum PlayerFilterLayout {
  /// 縦積みのサイドパネル(タブレット・PCの横置き)。
  panel,

  /// 検索と条件を横一列に並べる(一覧の上に置く中幅向け)。
  inline,

  /// 検索欄を常に表示し、条件は折りたたむ(スマホ向け)。
  compact,
}

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
    this.layout = PlayerFilterLayout.panel,
    this.expanded = false,
    this.onExpandedChanged,
  });

  final String searchQuery;
  final String grade;
  final String position;
  final String sortType;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onGradeChanged;
  final ValueChanged<String> onPositionChanged;
  final ValueChanged<String> onSortChanged;

  final PlayerFilterLayout layout;

  /// [PlayerFilterLayout.compact] で条件欄を開いているか。
  /// 開閉状態は呼び出し側で保持する(タブ切り替えで状態を残すため)。
  final bool expanded;
  final ValueChanged<bool>? onExpandedChanged;

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

  /// 「全員」以外が選ばれている絞り込み条件の数(並び順は含めない)。
  int get _activeFilterCount =>
      (widget.grade != '全員' ? 1 : 0) + (widget.position != '全員' ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final content = switch (widget.layout) {
      PlayerFilterLayout.panel => _buildPanel(),
      PlayerFilterLayout.inline => _buildInline(),
      PlayerFilterLayout.compact => _buildCompact(),
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: widget.layout == PlayerFilterLayout.panel
              ? const EdgeInsets.fromLTRB(18, 24, 18, 20)
              : const EdgeInsets.fromLTRB(14, 18, 14, 14),
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
          child: content,
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

  Widget _buildPanel() {
    return Column(
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
        _searchField(),
        const SizedBox(height: 16),
        ..._labeledDropdown('GRADE', widget.grade, PlayerFilterBar.grades,
            widget.onGradeChanged),
        const SizedBox(height: 16),
        ..._labeledDropdown('POSITION', widget.position,
            PlayerFilterBar.positions, widget.onPositionChanged),
        const SizedBox(height: 16),
        ..._labeledDropdown('SORT', widget.sortType, PlayerFilterBar.sortTypes,
            widget.onSortChanged),
      ],
    );
  }

  Widget _buildInline() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(flex: 2, child: _searchField()),
        const SizedBox(width: 12),
        Expanded(child: _conditionColumn(0)),
        const SizedBox(width: 10),
        Expanded(child: _conditionColumn(1)),
        const SizedBox(width: 10),
        Expanded(child: _conditionColumn(2)),
      ],
    );
  }

  Widget _buildCompact() {
    final count = _activeFilterCount;
    final label = count > 0 ? '絞り込み ($count)' : '絞り込み';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _searchField()),
            const SizedBox(width: 8),
            Semantics(
              expanded: widget.expanded,
              child: OutlinedButton.icon(
                onPressed: widget.onExpandedChanged == null
                    ? null
                    : () => widget.onExpandedChanged!(!widget.expanded),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: count > 0
                      ? AppColors.accent
                      : AppColors.textPrimary,
                  side: BorderSide(
                    color: count > 0
                        ? AppColors.accent
                        : const Color(0xFFDDD8CE),
                  ),
                  backgroundColor: Colors.white,
                ),
                icon: Icon(
                  widget.expanded ? Icons.expand_less : Icons.tune,
                  size: 20,
                ),
                label: Text(label),
              ),
            ),
          ],
        ),
        if (widget.expanded) ...[
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              // 3条件を横に並べられない極端に狭い幅では縦に積む。
              if (constraints.maxWidth < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _conditionColumn(i),
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _conditionColumn(i)),
                  ],
                ],
              );
            },
          ),
        ],
      ],
    );
  }

  /// 0: 学年 / 1: ポジション / 2: 並び順
  Widget _conditionColumn(int index) {
    final children = switch (index) {
      0 => _labeledDropdown('GRADE', widget.grade, PlayerFilterBar.grades,
          widget.onGradeChanged),
      1 => _labeledDropdown('POSITION', widget.position,
          PlayerFilterBar.positions, widget.onPositionChanged),
      _ => _labeledDropdown('SORT', widget.sortType,
          PlayerFilterBar.sortTypes, widget.onSortChanged),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  List<Widget> _labeledDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return [
      _FieldLabel(label),
      const SizedBox(height: 6),
      _dropdown(value: value, items: items, onChanged: onChanged),
    ];
  }

  Widget _searchField() {
    return TextField(
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
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
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
