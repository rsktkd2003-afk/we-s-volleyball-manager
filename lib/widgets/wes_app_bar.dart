import 'package:flutter/material.dart';

class WesAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WesAppBar({
    super.key,
    this.unreadCount = 0,
    this.onTapNotifications,
    this.onTapSettings,
  });

  final int unreadCount;
  final VoidCallback? onTapNotifications;
  final VoidCallback? onTapSettings;

  static const Color _red = Color(0xFFD32F2F);
  static const Color _paper = Color(0xFFFFFDF7);
  static const Color _textMain = Color(0xFF333333);

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 76,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 12,
      title: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 4),
              color: Color(0x33000000),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.sports_volleyball,
              color: _red,
              size: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "We's\n",
                      style: TextStyle(
                        color: _red,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: 'Volleyball Manager',
                      style: TextStyle(
                        color: _textMain,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _NotificationButton(
              unreadCount: unreadCount,
              onTap: onTapNotifications,
            ),
            IconButton(
              onPressed: onTapSettings,
              icon: const Icon(Icons.settings),
              color: _textMain,
              tooltip: '設定',
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback? onTap;

  static const Color _red = Color(0xFFD32F2F);
  static const Color _textMain = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.notifications_outlined),
          color: _textMain,
          tooltip: '通知',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 7,
            top: 7,
            child: Container(
              constraints: const BoxConstraints(minWidth: 17),
              height: 17,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: const BoxDecoration(
                color: _red,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}