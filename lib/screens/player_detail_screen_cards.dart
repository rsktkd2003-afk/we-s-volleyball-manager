part of 'player_detail_screen.dart';

class _NumberCard extends StatelessWidget {
  const _NumberCard({
    required this.player,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.012,
      child: _PaperCard(
        paperColor: const Color(0xFFE8D4AA),
        pinColor: const Color(0xFFC0392B),
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFC0392B),
                  width: 2,
                ),
              ),
              child: const Text(
                'PLAYER CARD',
                style: TextStyle(
                  color: Color(0xFF9E2E24),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.2,
                ),
              ),
            ),
            const SizedBox(height: 18),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                player.number.toString(),
                style: const TextStyle(
                  color: Color(0xFFC0392B),
                  fontSize: 150,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              color: const Color(0xFFC0392B),
              child: Text(
                player.position.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              player.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF242424),
                fontSize: 27,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhysicalDataCard extends StatelessWidget {
  const _PhysicalDataCard({
    required this.player,
  });

  final Player player;

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final values = [
      _LabelValue(
        label: '身長',
        value: '${_formatNumber(player.height)} cm',
      ),
      _LabelValue(
        label: '体重',
        value: '${_formatNumber(player.weight)} kg',
      ),
      _LabelValue(
        label: '指高（立位）',
        value: '${_formatNumber(player.standingReach)} cm',
      ),
      _LabelValue(
        label: '最高到達点',
        value: '${_formatNumber(player.maxReach)} cm',
      ),
      _LabelValue(
        label: 'ブロック到達点',
        value: '${_formatNumber(player.blockReach)} cm',
      ),
      _LabelValue(
        label: 'ジャンプ高',
        value: '${_formatNumber(player.jumpHeight)} cm',
      ),
      _LabelValue(
        label: '利き手',
        value: player.dominantHand,
      ),
      _LabelValue(
        label: '学年',
        value: player.grade,
      ),
    ];

    return Transform.rotate(
      angle: 0.007,
      child: _PaperCard(
        pinColor: const Color(0xFF315D91),
        tapeTopRight: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(title: 'PHYSICAL DATA'),
            const SizedBox(height: 8),
            for (final item in values)
              _UnderlinedDataRow(
                label: item.label,
                value: item.value,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerInformationCard extends StatelessWidget {
  const _PlayerInformationCard({
    required this.player,
  });

  final Player player;

  List<String> _createStrengths() {
    final strengths = <String>[];

    if (player.block >= 7) {
      strengths.add('高いブロック力');
    }

    if (player.spike >= 7) {
      strengths.add('スパイクの決定力');
    }

    if (player.serve >= 7) {
      strengths.add('強力なサーブ');
    }

    if (player.reception >= 7) {
      strengths.add('安定したレセプション');
    }

    if (player.dig >= 7) {
      strengths.add('高いディグ能力');
    }

    if (player.toss >= 7) {
      strengths.add('正確なトス');
    }

    if (player.mobility >= 7) {
      strengths.add('高い機動力');
    }

    if (player.maxReach >= 300) {
      strengths.add('高い最高到達点');
    }

    if (strengths.isEmpty) {
      strengths.add('能力値を編集中');
    }

    return strengths.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final information = [
      _LabelValue(label: '氏名', value: player.name),
      _LabelValue(label: '背番号', value: player.number.toString()),
      _LabelValue(label: 'ポジション', value: player.position),
      _LabelValue(label: '学年', value: player.grade),
      _LabelValue(label: '利き手', value: player.dominantHand),
      _LabelValue(
        label: 'ジャンプ高',
        value: '${player.jumpHeight.toStringAsFixed(1)} cm',
      ),
    ];

    final strengths = _createStrengths();

    return Transform.rotate(
      angle: 0.003,
      child: _PaperCard(
        pinColor: const Color(0xFFC0392B),
        padding: const EdgeInsets.fromLTRB(32, 34, 32, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(title: 'PLAYER INFORMATION'),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final useTwoColumns = constraints.maxWidth >= 500;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: information.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: useTwoColumns ? 2 : 1,
                    mainAxisExtent: 90,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 30,
                  ),
                  itemBuilder: (context, index) {
                    final item = information[index];

                    return _InformationField(
                      label: item.label,
                      value: item.value,
                    );
                  },
                );
              },
            ),
            if (player.roles.isNotEmpty) ...[
              const SizedBox(height: 28),
              const Text(
                'ROLES',
                style: TextStyle(
                  color: Color(0xFF272727),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final role in player.roles)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFCF6),
                        border: Border.all(
                          color: const Color(0xFFD8D2C6),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PlayerRoles.iconFor(role),
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            PlayerRoles.displayName(role),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 28),
            const Text(
              'KEY STRENGTHS',
              style: TextStyle(
                color: Color(0xFF272727),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (int index = 0; index < strengths.length; index++)
                  Transform.rotate(
                    angle: index.isEven ? -0.008 : 0.008,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFCF6),
                        border: Border.all(
                          color: const Color(0xFFC95A50),
                        ),
                      ),
                      child: Text(
                        strengths[index],
                        style: const TextStyle(
                          color: Color(0xFFB1392E),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AbilityCard extends StatelessWidget {
  const _AbilityCard({
    required this.player,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    final values = <String, int>{
      'スパイク': player.spike,
      'サーブ': player.serve,
      'レセプ': player.reception,
      'ディグ': player.dig,
      'トス': player.toss,
      'ブロック': player.block,
      '機動力': player.mobility,
    };

    return Transform.rotate(
      angle: 0.009,
      child: _PaperCard(
        pinColor: const Color(0xFF315D91),
        tapeTopLeft: true,
        tapeTopRight: true,
        padding: const EdgeInsets.fromLTRB(22, 34, 22, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(title: 'ABILITY RADAR'),
            const SizedBox(height: 8),
            AbilityRadarChart(values: values),
            const SizedBox(height: 14),
            const Divider(
              color: Color(0xFFD0CBC0),
              height: 1,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: values.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 38,
                crossAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final entry = values.entries.elementAt(index);

                return Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC0392B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      (entry.value * 10).toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PositionSuitabilitySection extends StatelessWidget {
  const _PositionSuitabilitySection({
    required this.player,
  });

  final Player player;

  static const Map<String, Color> _colors = {
    'WS': Color(0xFFC0392B),
    'MB': Color(0xFF315D91),
    'OP': Color(0xFF74502F),
    'S': Color(0xFF356B46),
  };

  static const Map<String, String> _displayNames = {
    'WS': 'WS',
    'MB': 'MB',
    'OP': 'OP',
    'S': 'SET',
  };

  static const Map<String, String> _comments = {
    'WS': 'スパイク・レセプション・守備力を生かせるポジション',
    'MB': 'ブロック力と機動力を生かして中央を守れるポジション',
    'OP': '攻撃力とブロック力を中心に得点を狙えるポジション',
    'S': 'トス精度と機動力を使ってゲームを組み立てるポジション',
  };

  @override
  Widget build(BuildContext context) {
    final allScores = PositionFitService.calculate(player);

    final scores = <String, double>{
      for (final key in ['WS', 'MB', 'OP', 'S'])
        if (allScores.containsKey(key)) key: allScores[key]!,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text(
            'POSITION SUITABILITY',
            style: TextStyle(
              color: Color(0xFF252525),
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 4 : 2;
            final cardWidth =
                (constraints.maxWidth - ((columns - 1) * 14)) / columns;

            return Wrap(
              spacing: 14,
              runSpacing: 18,
              children: [
                for (int index = 0; index < scores.length; index++)
                  SizedBox(
                    width: cardWidth,
                    child: _PositionCard(
                      code: scores.keys.elementAt(index),
                      displayName:
                          _displayNames[scores.keys.elementAt(index)] ??
                              scores.keys.elementAt(index),
                      score: scores.values.elementAt(index),
                      color: _colors[scores.keys.elementAt(index)] ??
                          const Color(0xFF555555),
                      comment: _comments[scores.keys.elementAt(index)] ?? '',
                      angle: index.isEven ? -0.008 : 0.008,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PositionCard extends StatelessWidget {
  const _PositionCard({
    required this.code,
    required this.displayName,
    required this.score,
    required this.color,
    required this.comment,
    required this.angle,
  });

  final String code;
  final String displayName;
  final double score;
  final Color color;
  final String comment;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final percentage = (score * 10).clamp(0, 100).round();

    return Transform.rotate(
      angle: angle,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 265),
            padding: const EdgeInsets.fromLTRB(18, 34, 18, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5ED),
              border: Border.all(
                color: const Color(0xFFD6D0C3),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x35000000),
                  blurRadius: 12,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: color,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    color: color,
                    fontSize: 43,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 17),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFDDD4C3),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  comment,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.65,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -10,
            child: PinBadge(
              size: 21,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _IssueMemoCard extends StatelessWidget {
  const _IssueMemoCard();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.01,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
            decoration: const BoxDecoration(
              color: Color(0xFFE8D06F),
              boxShadow: [
                BoxShadow(
                  color: Color(0x38000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLAYER ISSUES',
                  style: TextStyle(
                    color: Color(0xFF9F3026),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 12),
                Divider(
                  color: Color(0x55724822),
                ),
                SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_upward,
                      size: 20,
                      color: Color(0xFF5A451B),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '登録済みの改善点は、画面上部の「改善点」タブから確認・追加できます。',
                        style: TextStyle(
                          color: Color(0xFF3D321B),
                          fontSize: 16,
                          height: 1.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Positioned(
            top: -10,
            child: PinBadge(
              size: 21,
              color: Color(0xFFC0392B),
            ),
          ),
        ],
      ),
    );
  }
}
