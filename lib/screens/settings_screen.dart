import 'package:flutter/material.dart';

import '../models/app_notification_status.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cork_board_background.dart';
import '../widgets/pinned_paper_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppNotificationStatus? notificationStatus;
  bool isLoading = true;
  bool isUpdating = false;
  bool isSendingTestNotification = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> loadSettings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final status = await NotificationService.loadStatus();
      if (!mounted) return;

      setState(() {
        notificationStatus = status;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = '設定の読み込みに失敗しました: $error';
        isLoading = false;
      });
    }
  }

  Future<void> updateNotifications(bool enabled) async {
    if (isUpdating) return;

    setState(() {
      isUpdating = true;
      errorMessage = null;
    });

    try {
      final status = await NotificationService.setEnabled(enabled);
      if (!mounted) return;

      setState(() => notificationStatus = status);

      if (enabled && !status.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status.description)),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = '通知設定の更新に失敗しました: $error';
      });
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  Future<void> sendTestNotification() async {
    if (isSendingTestNotification) return;

    setState(() {
      isSendingTestNotification = true;
      errorMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('8秒後に送信します。Chromeの別タブへ切り替えてください。'),
      ),
    );

    try {
      final result = await NotificationService.sendTestNotification();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'テスト通知を${result.successCount}台の端末へ送信しました。',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'テスト通知の送信に失敗しました: $error';
      });
    } finally {
      if (mounted) {
        setState(() => isSendingTestNotification = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.headerDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('設定'),
      ),
      body: CorkBoardBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: PinnedPaperCard(
                  margin: EdgeInsets.zero,
                  showTape: true,
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _buildSettingsContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContent() {
    final status = notificationStatus;

    if (status == null) {
      return Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.accent, size: 48),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? '設定を読み込めませんでした。',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: loadSettings,
            icon: const Icon(Icons.refresh),
            label: const Text('再読み込み'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.settings_outlined,
          color: AppColors.textPrimary,
          size: 48,
        ),
        const SizedBox(height: 12),
        const Text(
          'アプリ設定',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'この端末で使用するアプリの設定を管理します。',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3DFD5)),
          ),
          child: Column(
            children: [
              SwitchListTile(
                value: status.preferenceEnabled,
                onChanged: status.canChange && !isUpdating
                    ? updateNotifications
                    : null,
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text(
                  '通知',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('この端末で通知を受け取る'),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      status.isActive
                          ? Icons.check_circle_outline
                          : Icons.info_outline,
                      color: status.isActive
                          ? Colors.green.shade700
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.permissionLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status.description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUpdating)
                      const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '通知設定は端末ごとに保存されます。通知が拒否されている場合は、ブラウザまたは端末の設定から許可してください。',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        if (status.isActive) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: isSendingTestNotification
                ? null
                : sendTestNotification,
            icon: isSendingTestNotification
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(
              isSendingTestNotification
                  ? '送信準備中...'
                  : '8秒後にテスト通知を送る',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ボタンを押したらChromeの別タブへ切り替えて、バックグラウンド通知を確認してください。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ],
    );
  }
}
