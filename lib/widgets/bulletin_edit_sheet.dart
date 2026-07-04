import 'package:flutter/material.dart';

const Color _paper = Color(0xFFFFFDF7);
const Color _red = Color(0xFFD32F2F);
const Color _textMain = Color(0xFF333333);

/// お知らせ／今月の目標 共通の編集ボトムシートを開く。
/// Firestore操作は呼び出し側の onSubmit / onDelete に委譲する。
Future<void> showBulletinEditSheet({
  required BuildContext context,
  required String heading,
  String? initialTitle,
  String? initialBody,
  required Future<void> Function(String title, String body) onSubmit,
  Future<void> Function()? onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return BulletinEditSheet(
        heading: heading,
        initialTitle: initialTitle,
        initialBody: initialBody,
        onSubmit: onSubmit,
        onDelete: onDelete,
      );
    },
  );
}

class BulletinEditSheet extends StatefulWidget {
  const BulletinEditSheet({
    super.key,
    required this.heading,
    required this.onSubmit,
    this.initialTitle,
    this.initialBody,
    this.onDelete,
  });

  final String heading;
  final String? initialTitle;
  final String? initialBody;
  final Future<void> Function(String title, String body) onSubmit;
  final Future<void> Function()? onDelete;

  @override
  State<BulletinEditSheet> createState() => _BulletinEditSheetState();
}

class _BulletinEditSheetState extends State<BulletinEditSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;

  bool _saving = false;
  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle ?? '');
    _bodyCtrl = TextEditingController(text: widget.initialBody ?? '');
    _canSave = _titleCtrl.text.trim().isNotEmpty;
    _titleCtrl.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    final canSave = _titleCtrl.text.trim().isNotEmpty;
    if (canSave != _canSave) {
      setState(() => _canSave = canSave);
    }
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTitleChanged);
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _saving) return;

    setState(() => _saving = true);
    try {
      await widget.onSubmit(title, _bodyCtrl.text.trim());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    if (_saving) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('削除しますか？'),
          content: const Text('この内容を削除します。元に戻せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: _red),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await widget.onDelete?.call();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final canDelete = widget.onDelete != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.heading,
                style: const TextStyle(
                  color: _textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _titleCtrl,
                maxLength: 50,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'タイトル（必須）',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _bodyCtrl,
                maxLength: 500,
                maxLines: 4,
                minLines: 2,
                decoration: const InputDecoration(
                  labelText: '本文（任意）',
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (canDelete)
                    TextButton.icon(
                      onPressed: _saving ? null : _confirmDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('削除'),
                      style: TextButton.styleFrom(foregroundColor: _red),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: (_canSave && !_saving) ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}