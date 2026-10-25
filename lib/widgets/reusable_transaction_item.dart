import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// A reusable glassmorphic card that displays a single transaction.
/// Accepts an [onLongPress] callback so any parent screen can handle deletion.
class ReusableTransactionItem extends StatelessWidget {
  final String title;
  final int amount;
  final IconData icon;
  final VoidCallback? onLongPress;

  const ReusableTransactionItem({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    this.onLongPress,
  });

  /// Formats an integer like 2500000 → "2,500,000"
  String _formatAmount(int value) {
    return value
        .abs()
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCredit = amount > 0;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            // Icon avatar
            CircleAvatar(
              backgroundColor: isCredit
                  ? AppColors.successGreen.withValues(alpha: 0.25)
                  : AppColors.primary.withValues(alpha: 0.25),
              child: Icon(
                icon,
                color: isCredit ? AppColors.successGreen : Colors.white70,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),

            // Title + long-press hint
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (onLongPress != null)
                    Text(
                      'Long-press to delete',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                ],
              ),
            ),

            // Amount chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isCredit
                    ? AppColors.successGreen.withValues(alpha: 0.15)
                    : AppColors.errorRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${isCredit ? '+' : '-'} UGX ${_formatAmount(amount)}',
                style: TextStyle(
                  color: isCredit ? AppColors.successGreen : AppColors.errorRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
