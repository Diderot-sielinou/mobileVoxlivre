import 'package:flutter/material.dart';
import 'package:voxlivre/src/features/library/domain/document_title.dart';

/// « Renommer » (menu ⋮ de la fiche). [onSubmit] rend `null` si c'est fait,
/// sinon le code de l'échec. Rend `true` si le document a été renommé.
Future<bool> showRenameDocumentDialog(
  BuildContext context, {
  required String initialTitle,
  required Future<String?> Function(String title) onSubmit,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) =>
          _RenameDialog(initialTitle: initialTitle, onSubmit: onSubmit),
    ) ??
    false;

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialTitle, required this.onSubmit});

  final String initialTitle;
  final Future<String?> Function(String title) onSubmit;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _title = TextEditingController(text: widget.initialTitle)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialTitle.length,
    );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final code = await widget.onSubmit(_title.text);
    if (!mounted) return;
    if (code == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = switch (code) {
        'INVALID_DOCUMENT_TITLE' =>
          'Entrez un titre de 1 à ${DocumentTitle.maxLength} caractères.',
        'NETWORK_UNAVAILABLE' ||
        'TIMEOUT' => 'Pas de connexion : le titre n’a pas été changé.',
        _ => 'Le titre n’a pas pu être changé. Réessayez.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renommer le document'),
      content: TextField(
        controller: _title,
        autofocus: true,
        enabled: !_busy,
        maxLength: DocumentTitle.maxLength,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Titre',
          errorText: _error,
          errorMaxLines: 3,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Renommer'),
        ),
      ],
    );
  }
}
