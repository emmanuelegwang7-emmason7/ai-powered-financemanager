import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/finance_store.dart';

/// Smart "Safe to Spend" card for the Home screen.
///
/// Shows a live 3-layer calculation:
///   MoMo Balance − Committed Expenses = Free Balance
///   Free Balance − Today's Spending   = Safe to Spend NOW
///
/// States:
///   • No balance checked → prompt to check MoMo
///   • Balance checked, no commitments → full balance is safe
///   • Balance + commitments → shows the full breakdown
///
/// Refreshes whenever [refreshKey] changes (parent calls setState).
class SafeToSpendCard extends StatefulWidget {
  /// Increment this from the parent to force a refresh of the card data.
  final int refreshKey;

  const SafeToSpendCard({super.key, this.refreshKey = 0});

  @override
  State<SafeToSpendCard> createState() => _SafeToSpendCardState();
}

class _SafeToSpendCardState extends State<SafeToSpendCard> {
  bool _detailsExpanded = false;
  bool _amountVisible = true;

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _fmt(int v) => v
      .abs()
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Color _safeColor(int? safe, int? free) {
    if (safe == null || free == null || free <= 0) return Colors.white;
    final ratio = safe / free;
    if (ratio > 0.5) return AppColors.successGreen;
    if (ratio > 0.2) return Colors.amber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    // Read fresh data every build
    final momoBalance = FinanceStore.getMomoBalance();
    final committed = FinanceStore.getCommittedExpenses();
    final totalCommitted = FinanceStore.getTotalCommitted();
    final todaySpending = FinanceStore.getTodaySpending();
    final freeBalance = FinanceStore.getFreeBalance();
    final safeToSpend = FinanceStore.getSafeToSpend();
    final checkedLabel = FinanceStore.getCheckedAtLabel();
    final telecom =
        FinanceStore.getMomoTelecom() == 'airtel' ? 'Airtel' : 'MTN';

    final safeColor = _safeColor(safeToSpend, freeBalance);
    final isOverBudget = safeToSpend != null && safeToSpend < 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.45),
                AppColors.bgGradientEnd.withValues(alpha: 0.55),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: momoBalance == null
              ? _buildNoBalanceState()
              : _buildCalculationState(
                  momoBalance: momoBalance,
                  totalCommitted: totalCommitted,
                  committed: committed,
                  todaySpending: todaySpending,
                  freeBalance: freeBalance!,
                  safeToSpend: safeToSpend!,
                  safeColor: safeColor,
                  isOverBudget: isOverBudget,
                  checkedLabel: checkedLabel,
                  telecom: telecom,
                ),
        ),
      ),
    );
  }

  // ── State: MoMo not checked yet ───────────────────────────────────────────
  Widget _buildNoBalanceState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white70, size: 22),
              const SizedBox(width: 8),
              Text('Safe to Spend',
                  style: AppTextStyles.subHeading.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Check your MoMo balance first.',
            style: AppTextStyles.body.copyWith(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Once your balance is loaded, this card will show\nexactly how much is safe to spend today.',
            style: AppTextStyles.body
                .copyWith(fontSize: 13, color: Colors.white54),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '↓ Use the MoMo card below',
              style: AppTextStyles.body.copyWith(
                  fontSize: 12, color: Colors.white60),
            ),
          ),
        ],
      ),
    );
  }

  // ── State: full calculation ───────────────────────────────────────────────
  Widget _buildCalculationState({
    required int momoBalance,
    required int totalCommitted,
    required List<CommittedExpense> committed,
    required int todaySpending,
    required int freeBalance,
    required int safeToSpend,
    required Color safeColor,
    required bool isOverBudget,
    required String checkedLabel,
    required String telecom,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safe to Spend Now',
                    style: AppTextStyles.body.copyWith(
                        fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  // ── Main number ────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _amountVisible
                            ? (isOverBudget
                                ? '− UGX ${_fmt(safeToSpend.abs())}'
                                : 'UGX ${_fmt(safeToSpend)}')
                            : 'UGX ••••••',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _amountVisible ? safeColor : Colors.white54,
                          letterSpacing: _amountVisible ? 0 : 3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _amountVisible = !_amountVisible),
                        child: Icon(
                          _amountVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white38,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: safeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: safeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  isOverBudget
                      ? '⚠ Over Budget'
                      : safeToSpend > freeBalance * 0.5
                          ? '✓ Healthy'
                          : safeToSpend > freeBalance * 0.2
                              ? '⚡ Watch Out'
                              : '🔴 Running Low',
                  style: TextStyle(
                    fontSize: 11,
                    color: safeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 10),

          // ── Breakdown rows ─────────────────────────────────────────
          _row('$telecom Balance', _fmt(momoBalance), Colors.white),
          if (totalCommitted > 0)
            _row('− Committed Expenses', _fmt(totalCommitted),
                AppColors.errorRed.withValues(alpha: 0.85)),
          _row('= Free Balance', _fmt(freeBalance),
              Colors.white.withValues(alpha: 0.7)),
          if (todaySpending > 0)
            _row("− Today's Spending", _fmt(todaySpending),
                Colors.amber.withValues(alpha: 0.9)),

          // ── Expand to see committed breakdown ──────────────────────
          if (committed.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () =>
                  setState(() => _detailsExpanded = !_detailsExpanded),
              child: Row(
                children: [
                  Icon(
                    _detailsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.white38,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _detailsExpanded
                        ? 'Hide breakdown'
                        : 'See ${committed.length} committed expense'
                            '${committed.length == 1 ? '' : 's'}',
                    style: AppTextStyles.body.copyWith(
                        fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
            ),
            if (_detailsExpanded) ...[
              const SizedBox(height: 8),
              ...committed.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: _row('  · ${e.name}', _fmt(e.amount),
                      AppColors.errorRed.withValues(alpha: 0.65),
                      small: true),
                ),
              ),
            ],
          ],

          const SizedBox(height: 10),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 6),

          // ── Footer timestamp ───────────────────────────────────────
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 12, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(width: 4),
              Text(
                'Balance checked: $checkedLabel',
                style: AppTextStyles.body.copyWith(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.3)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor,
      {bool small = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.body.copyWith(
                  fontSize: small ? 12 : 13,
                  color: Colors.white.withValues(alpha: 0.65))),
          Text('UGX $value',
              style: TextStyle(
                  fontSize: small ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor)),
        ],
      ),
    );
  }
}
