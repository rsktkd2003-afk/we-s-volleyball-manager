import 'package:flutter/material.dart';

import '../dialogs/logout_confirmation_dialog.dart';
import '../services/account_service.dart';
import '../theme/app_colors.dart';
import '../utils/account_validation.dart';
import '../widgets/cork_board_background.dart';
import '../widgets/pinned_paper_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final displayNameController = TextEditingController();
  final emailController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool isLoggingOut = false;
  String? displayNameError;
  String? loadError;

  bool get isBusy => isSaving || isLoggingOut;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    displayNameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final profile = await AccountService.loadCurrentProfile();
      if (!mounted) return;

      displayNameController.text = profile.displayName;
      emailController.text = profile.email;
      setState(() => isLoading = false);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loadError = 'プロフィールの読み込みに失敗しました: $error';
        isLoading = false;
      });
    }
  }

  Future<void> saveProfile() async {
    FocusScope.of(context).unfocus();
    final validationError = validateDisplayName(displayNameController.text);
    if (validationError != null) {
      setState(() => displayNameError = validationError);
      return;
    }

    setState(() {
      isSaving = true;
      displayNameError = null;
    });

    try {
      await AccountService.updateDisplayName(displayNameController.text);
      if (!mounted) return;

      displayNameController.text =
          normalizeDisplayName(displayNameController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィールを更新しました')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('プロフィールの更新に失敗しました: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> logout() async {
    final confirmed = await showLogoutConfirmationDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => isLoggingOut = true);

    try {
      await AccountService.signOut();
      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (error) {
      if (!mounted) return;

      setState(() => isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログアウトに失敗しました: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.headerDark,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('プロフィール'),
      ),
      body: CorkBoardBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: PinnedPaperCard(
                  margin: EdgeInsets.zero,
                  showTape: true,
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : loadError != null
                          ? _buildLoadError()
                          : _buildProfileForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadError() {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: AppColors.accent, size: 48),
        const SizedBox(height: 16),
        Text(loadError!, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: loadProfile,
          icon: const Icon(Icons.refresh),
          label: const Text('再読み込み'),
        ),
      ],
    );
  }

  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CircleAvatar(
          radius: 38,
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          child: Icon(Icons.person, size: 44),
        ),
        const SizedBox(height: 16),
        const Text(
          'アカウント情報',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'チーム内で表示するユーザーネームを編集できます。',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: displayNameController,
          enabled: !isBusy,
          textInputAction: TextInputAction.done,
          onSubmitted: isBusy ? null : (_) => saveProfile(),
          onChanged: (_) {
            if (displayNameError != null) {
              setState(() => displayNameError = null);
            }
          },
          decoration: InputDecoration(
            labelText: 'ユーザーネーム',
            prefixIcon: const Icon(Icons.badge_outlined),
            border: const OutlineInputBorder(),
            errorText: displayNameError,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          readOnly: true,
          enableInteractiveSelection: true,
          decoration: const InputDecoration(
            labelText: 'メールアドレス',
            prefixIcon: Icon(Icons.mail_outline),
            border: OutlineInputBorder(),
            helperText: 'メールアドレスは現在変更できません',
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: isBusy ? null : saveProfile,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(isSaving ? '保存中...' : '変更を保存'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isBusy ? null : logout,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent,
            side: const BorderSide(color: AppColors.accent),
          ),
          icon: isLoggingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: Text(isLoggingOut ? 'ログアウト中...' : 'ログアウト'),
        ),
      ],
    );
  }
}
