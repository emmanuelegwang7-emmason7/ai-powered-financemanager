import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// A reusable confirmation dialog for any destructive action.
/// Returns [true] if the user confirms, [false] / null if they cancel.
///
/// Usage:
/// ```dart
/// final confirmed = await showDeleteConfirmationDialog(
///   context: context,
///   itemName: 'Uber Ride',
/// );
/// if (confirmed == true) { /* delete the item */ }
/// ```
Future<bool?> showDeleteConfirmationDialog({
  required BuildContext context,
  required String itemName,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1E293B), // dark navy glass
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppColors.errorRed),
            const SizedBox(width: 10),
            Text('Delete Transaction', style: AppTextStyles.subHeading),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: AppTextStyles.body,
            children: [
              const TextSpan(text: 'Remove '),
              TextSpan(
                text: '"$itemName"',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: ' from your history? This cannot be undone.'),
            ],
          ),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: AppTextStyles.body.copyWith(color: Colors.white60),
            ),
          ),

          // Confirm delete button
          ElevatedButton.icon(
            icon: const Icon(Icons.delete, size: 18, color: Colors.white),
            label: const Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      );
    },
  );
}
