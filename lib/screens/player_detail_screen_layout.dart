part of 'player_detail_screen.dart';

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.player,
  });

  final Player player;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 280,
          child: Column(
            children: [
              _NumberCard(player: player),
              const SizedBox(height: 26),
              _PhysicalDataCard(player: player),
            ],
          ),
        ),
        const SizedBox(width: 26),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _PlayerInformationCard(player: player),
              const SizedBox(height: 28),
              _PositionSuitabilitySection(player: player),
            ],
          ),
        ),
        const SizedBox(width: 26),
        SizedBox(
          width: 385,
          child: Column(
            children: [
              _AbilityCard(player: player),
              const SizedBox(height: 28),
              const _IssueMemoCard(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.player,
    required this.isTablet,
  });

  final Player player;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    if (!isTablet) {
      return Column(
        children: [
          _NumberCard(player: player),
          const SizedBox(height: 24),
          _PlayerInformationCard(player: player),
          const SizedBox(height: 24),
          _PhysicalDataCard(player: player),
          const SizedBox(height: 24),
          _AbilityCard(player: player),
          const SizedBox(height: 24),
          _PositionSuitabilitySection(player: player),
          const SizedBox(height: 24),
          const _IssueMemoCard(),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 260,
              child: Column(
                children: [
                  _NumberCard(player: player),
                  const SizedBox(height: 24),
                  _PhysicalDataCard(player: player),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _PlayerInformationCard(player: player),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _AbilityCard(player: player),
        const SizedBox(height: 24),
        _PositionSuitabilitySection(player: player),
        const SizedBox(height: 24),
        const _IssueMemoCard(),
      ],
    );
  }
}
