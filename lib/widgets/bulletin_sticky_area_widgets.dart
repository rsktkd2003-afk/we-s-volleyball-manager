part of 'bulletin_sticky_area.dart';

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onAdd,
  });

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF5D4037),
              ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('追加'),
        ),
      ],
    );
  }
}

class _AnnouncementWrap extends StatelessWidget {
  const _AnnouncementWrap({
    required this.items,
    required this.onTap,
    required this.onAdd,
  });

  final List<Announcement> items;
  final ValueChanged<Announcement> onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return BulletinNoteTile(
        heading: 'お知らせ',
        title: null,
        body: null,
        emptyText: '＋ タップして追加',
        color: const Color(0xFFFFF3B0),
        rotation: -0.02,
        pinColor: const Color(0xFFD32F2F),
        onTap: onAdd,
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 14,
      children: [
        for (var i = 0; i < items.length; i++)
          BulletinNoteTile(
            heading: items[i].isPinned ? '📌 お知らせ' : 'お知らせ',
            title: items[i].title,
            body: items[i].body,
            emptyText: '',
            color: const Color(0xFFFFF3B0),
            rotation: _rotationForIndex(i),
            pinColor: const Color(0xFFD32F2F),
            onTap: () => onTap(items[i]),
          ),
      ],
    );
  }
}

class _GoalWrap extends StatelessWidget {
  const _GoalWrap({
    required this.items,
    required this.onTap,
    required this.onAdd,
  });

  final List<TeamGoal> items;
  final ValueChanged<TeamGoal> onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return BulletinNoteTile(
        heading: '今月の目標',
        title: null,
        body: null,
        emptyText: '＋ タップして追加',
        color: const Color(0xFFCDEFFF),
        rotation: 0.02,
        pinColor: const Color(0xFFD32F2F),
        onTap: onAdd,
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 14,
      children: [
        for (var i = 0; i < items.length; i++)
          BulletinNoteTile(
            heading: '今月の目標',
            title: items[i].title,
            body: items[i].body,
            emptyText: '',
            color: const Color(0xFFCDEFFF),
            rotation: _rotationForIndex(i + 2),
            pinColor: const Color(0xFFD32F2F),
            onTap: () => onTap(items[i]),
          ),
      ],
    );
  }
}

class _LoadingMemo extends StatelessWidget {
  const _LoadingMemo();

  @override
  Widget build(BuildContext context) {
    return const BulletinNoteTile(
      heading: '読み込み中',
      title: null,
      body: null,
      emptyText: '掲示板を読み込んでいます...',
      color: Color(0xFFFFF8D8),
      rotation: -0.01,
      pinColor: Color(0xFFD32F2F),
    );
  }
}

class _ErrorMemo extends StatelessWidget {
  const _ErrorMemo({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return BulletinNoteTile(
      heading: '読み込みエラー',
      title: '掲示板を読み込めませんでした',
      body: message,
      emptyText: '',
      color: const Color(0xFFFFD6D6),
      rotation: 0.01,
      pinColor: const Color(0xFFD32F2F),
    );
  }
}

double _rotationForIndex(int index) {
  const values = [-0.028, 0.018, -0.012, 0.026, -0.02, 0.014];
  return values[index % values.length];
}