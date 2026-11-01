import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/finance_store.dart';

/// Today's Plan Screen — the user declares all committed expenses
/// that will be deducted from the MoMo balance.
///
/// Formula shown live:
///   MoMo Balance − Committed Expenses = Free / Safe Balance
class TodaysPlanScreen extends StatefulWidget {
  const TodaysPlanScreen({super.key});

  @override
  State<TodaysPlanScreen> createState() => _TodaysPlanScreenState();
}

class _TodaysPlanScreenState extends State<TodaysPlanScreen> {
  List<CommittedExpense> _expenses = [];
  int? _momoBalance;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _expenses = FinanceStore.getCommittedExpenses();
      _momoBalance = FinanceStore.getMomoBalance();
    });
  }

  // ── Computed values ─────────────────────────────────────────────────────
  int get _totalCommitted =>
      _expenses.fold(0, (sum, e) => sum + e.amount);

  int? get _freeBalance =>
      _momoBalance != null ? _momoBalance! - _totalCommitted : null;

  // ── Add expense bottom sheet ─────────────────────────────────────────────
  void _showAddExpenseSheet() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
              color: const Color(0xFF1E293B),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    Text('Add Committed Expense',
                        style: AppTextStyles.subHeading),
                    const SizedBox(height: 20),

                    // Expense name
                    TextFormField(
                      controller: nameCtrl,
                      style: AppTextStyles.body,
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDeco(
                        'Expense name (e.g. Rent, School Fees)',
                        Icons.label_outline,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Enter a name' : null,
                    ),
                    const SizedBox(height: 14),

                    // Amount
                    TextFormField(
                      controller: amountCtrl,
                      style: AppTextStyles.body,
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco('Amount (UGX)', Icons.payments_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter an amount';
                        }
                        final parsed = int.tryParse(v.replaceAll(',', ''));
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid positive amount';
                        }
                        if (_momoBalance != null &&
                            parsed > _momoBalance! - _totalCommitted) {
                          return 'Amount exceeds remaining free balance';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, color: Colors.white),
                      label:
                          Text('Add Expense', style: AppTextStyles.button),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final expense = CommittedExpense(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameCtrl.text.trim(),
                          amount: int.parse(
                            amountCtrl.text.replaceAll(',', ''),
                          ),
                        );
                        await FinanceStore.addCommittedExpense(expense);
                        if (mounted) {
                          Navigator.pop(context);
                          setState(() {
                            _expenses = FinanceStore.getCommittedExpenses();
                            _hasUnsavedChanges = false;
                          });
                          _showSavedSnack('${expense.name} added ✓');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteExpense(CommittedExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: Text('Remove Expense?', style: AppTextStyles.subHeading),
        content: Text(
          'Remove "${expense.name}" from your plan?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: AppTextStyles.body.copyWith(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FinanceStore.removeCommittedExpense(expense.id);
      setState(() => _expenses = FinanceStore.getCommittedExpenses());
      _showSavedSnack('${expense.name} removed');
    }
  }

  void _showSavedSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: AppTextStyles.body.copyWith(color: Colors.white)),
        backgroundColor: AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _fmt(int v) => v
      .abs()
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final free = _freeBalance;
    final isOverBudget = free != null && free < 0;

    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Today's Plan", style: AppTextStyles.heading),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Expense', style: AppTextStyles.button),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgGradientStart, AppColors.bgGradientEnd],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            children: [
              // ── Balance source header ──────────────────────────────────
              if (_momoBalance == null)
                _noBalanceWarning()
              else
                _balanceSummaryCard(free, isOverBudget),

              const SizedBox(height: 20),

              // ── Section title ──────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.playlist_add_check,
                      color: Colors.white70, size: 22),
                  const SizedBox(width: 8),
                  Text('Committed Expenses', style: AppTextStyles.subHeading),
                  const Spacer(),
                  if (_expenses.isNotEmpty)
                    Text(
                      '${_expenses.length} item${_expenses.length == 1 ? '' : 's'}',
                      style: AppTextStyles.body
                          .copyWith(fontSize: 13, color: Colors.white38),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Expense list ───────────────────────────────────────────
              if (_expenses.isEmpty)
                _emptyExpenseState()
              else
                ..._expenses.map((e) => _expenseRow(e)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Balance summary card ──────────────────────────────────────────────────
  Widget _balanceSummaryCard(int? free, bool isOverBudget) {
    final freeColor = isOverBudget
        ? AppColors.errorRed
        : (free != null && free < _momoBalance! * 0.2)
            ? Colors.amber
            : AppColors.successGreen;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.3),
                AppColors.bgGradientEnd.withValues(alpha: 0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              // MoMo balance row
              _calcRow(
                'MoMo Balance',
                'UGX ${_fmt(_momoBalance!)}',
                Colors.white,
                isTotal: false,
              ),
              const SizedBox(height: 10),

              // Each committed expense
              if (_expenses.isNotEmpty) ...[
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                ..._expenses.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _calcRow(
                      '− ${e.name}',
                      'UGX ${_fmt(e.amount)}',
                      AppColors.errorRed.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],

              Divider(color: Colors.white.withValues(alpha: 0.2), height: 20),

              // Free balance result
              _calcRow(
                isOverBudget ? '⚠ Over Budget!' : '✓ Free to Spend',
                isOverBudget
                    ? '− UGX ${_fmt(free!.abs())}'
                    : 'UGX ${_fmt(free ?? 0)}',
                freeColor,
                isTotal: true,
              ),

              if (isOverBudget)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Your committed expenses exceed your balance. '
                    'Remove some expenses or check a fresh balance.',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: AppColors.errorRed.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calcRow(String label, String value, Color valueColor,
      {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: isTotal ? 15 : 13,
            color: isTotal ? Colors.white : Colors.white70,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // ── Individual expense row ────────────────────────────────────────────────
  Widget _expenseRow(CommittedExpense expense) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: AppColors.errorRed, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.name,
                    style: AppTextStyles.body
                        .copyWith(color: Colors.white, fontSize: 15)),
                Text(
                  'UGX ${_fmt(expense.amount)}',
                  style: AppTextStyles.body.copyWith(
                      fontSize: 13, color: AppColors.errorRed),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.white38, size: 20),
            onPressed: () => _deleteExpense(expense),
          ),
        ],
      ),
    );
  }

  Widget _emptyExpenseState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.playlist_add,
              size: 52, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            'No committed expenses yet',
            style: AppTextStyles.subHeading
                .copyWith(color: Colors.white38, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "+ Add Expense" to list things like\nrent, fees, bills, or savings.',
            style: AppTextStyles.body
                .copyWith(color: Colors.white24, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _noBalanceWarning() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Check your MoMo balance first from the Home screen so the calculation is accurate.',
              style: AppTextStyles.body
                  .copyWith(fontSize: 13, color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body
          .copyWith(color: Colors.white30, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
      ),
      errorStyle: const TextStyle(color: AppColors.errorRed, fontSize: 12),
    );
  }
}
