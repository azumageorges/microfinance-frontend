import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Dialogues de confirmation / saisie partagés par les écrans.
class AppDialogs {
  const AppDialogs._();

  /// Confirmation simple. Renvoie `true` si l'action est confirmée.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    Color? confirmColor,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: confirmColor == null
                ? null
                : ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// Saisie d'un texte (motif de rejet, commentaire…).
  ///
  /// Renvoie `null` si l'utilisateur annule. Quand [required] vaut `true`,
  /// la validation empêche de confirmer un champ vide.
  static Future<String?> prompt(
    BuildContext context, {
    required String title,
    String? message,
    String? label,
    String? hint,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    Color? confirmColor,
    bool required = true,
    int maxLines = 3,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message != null) ...[
                Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: controller,
                maxLines: maxLines,
                decoration: InputDecoration(labelText: label, hintText: hint),
                validator: (v) => required && (v == null || v.trim().isEmpty)
                    ? 'Ce champ est obligatoire'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            style: confirmColor == null
                ? null
                : ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    final value = confirmed == true ? controller.text.trim() : null;
    controller.dispose();
    return value;
  }
}
