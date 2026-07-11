part of 'player_detail_screen.dart';

class _PaperCard extends StatelessWidget {
  const _PaperCard({
    required this.child,
    this.paperColor = const Color(0xFFF8F5ED),
    this.pinColor = const Color(0xFFC0392B),
    this.padding = const EdgeInsets.fromLTRB(24, 34, 24, 24),
    this.tapeTopLeft = false,
    this.tapeTopRight = false,
  });

  final Widget child;
  final Color paperColor;
  final Color pinColor;
  final EdgeInsets padding;
  final bool tapeTopLeft;
  final bool tapeTopRight;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: paperColor,
            border: Border.all(
              color: const Color(0xFFD8D2C6),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x36000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 3,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
        Positioned(
          top: -10,
          left: 0,
          right: 0,
          child: Center(
            child: PinBadge(
              size: 22,
              color: pinColor,
            ),
          ),
        ),
        if (tapeTopLeft)
          const Positioned(
            top: -8,
            left: -10,
            child: _MaskingTape(angle: -0.55),
          ),
        if (tapeTopRight)
          const Positioned(
            top: -8,
            right: -10,
            child: _MaskingTape(angle: 0.55),
          ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF242424),
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 1,
              color: const Color(0xFFD0CBC0),
            ),
            Container(
              width: 82,
              height: 2,
              color: const Color(0xFFC0392B),
            ),
          ],
        ),
      ],
    );
  }
}

class _InformationField extends StatelessWidget {
  const _InformationField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 9),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFD3CDC0),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 4,
            ),
            color: const Color(0xFFE9DFC5),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5F5A50),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF252525),
              fontSize: 22,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnderlinedDataRow extends StatelessWidget {
  const _UnderlinedDataRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 11,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFD2CCC0),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF242424),
              fontSize: 19,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaskingTape extends StatelessWidget {
  const _MaskingTape({
    required this.angle,
  });

  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 74,
        height: 22,
        decoration: BoxDecoration(
          color: const Color(0xB8E4D095),
          border: Border.all(
            color: const Color(0x33A58B4A),
          ),
        ),
      ),
    );
  }
}

class _BoardScrew extends StatelessWidget {
  const _BoardScrew();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [
            Color(0xFFF2F2F2),
            Color(0xFF9B9B99),
            Color(0xFF555553),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF6C6C69),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Transform.rotate(
        angle: math.pi / 4,
        child: Center(
          child: Container(
            width: 7,
            height: 1,
            color: const Color(0xFF555555),
          ),
        ),
      ),
    );
  }
}

class _LabelValue {
  const _LabelValue({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}
