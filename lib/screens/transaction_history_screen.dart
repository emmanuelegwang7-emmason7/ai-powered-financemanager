import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../widgets/reusable_transaction_item.dart';
import '../widgets/delete_confirmation_dialog.dart';

/// Transaction History Screen — satisfies M2 requirements:
/// • Dynamic collection with ListView.builder
/// • Long-press on item triggers the Delete Confirmation Dialog
/// • Uses the ReusableTransactionItem widget (Reusable Component requirement)
class TransactionHistoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final Function(List<Map<String, dynamic>>) onTransactionsChanged;

  const TransactionHistoryScreen({
    super.key,
    required this.transactions,
    required this.onTransactionsChanged,
  });

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late List<Map<String, dynamic>> _localTransactions;

  // Category filter
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Income',
    'Expense',
    'Food',
    'Transport',
    'Bills',
    'Airtime',
  ];

  @override
  void initState() {
    super.initState();
    // Work on a local copy; push changes back to parent via callback
    _localTransactions = List.from(widget.transactions);
  }

  /// Returns only the transactions matching the current filter.
  List<Map<String, dynamic>> get _filteredTransactions {
    if (_selectedFilter == 'All') return _localTransactions;
    if (_selectedFilter == 'Income') {
      return _localTransactions
          .where((tx) => (tx['amount'] as int) > 0)
          .toList();
    }
    if (_selectedFilter == 'Expense') {
      return _localTransactions
          .where((tx) => (tx['amount'] as int) < 0)
          .toList();
    }
    return _localTransactions
        .where(
          (tx) =>
              (tx['category'] as String?)?.toLowerCase() ==
              _selectedFilter.toLowerCase(),
        )
        .toList();
  }

  Future<void> _confirmDelete(int globalIndex) async {
    final tx = _localTransactions[globalIndex];
    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      itemName: tx['title'] as String,
    );

    if (confirmed == true) {
      setState(() => _localTransactions.removeAt(globalIndex));
      widget.onTransactionsChanged(_localTransactions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${tx['title']}" deleted',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                setState(() => _localTransactions.insert(globalIndex, tx));
                widget.onTransactionsChanged(_localTransactions);
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Transaction History', style: AppTextStyles.heading),
        actions: [
          // Total count badge
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_localTransactions.length} items',
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgGradientStart, AppColors.bgGradientEnd],
          ),
        ),
        child: Column(
          children: [
            // ── Filter chips ───────────────────────────────────────────────
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter == _selectedFilter;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // ── Transaction list ───────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        // Find the global index for deletion
                        final globalIndex = _localTransactions.indexOf(tx);

                        return ReusableTransactionItem(
                          title: tx['title'] as String,
                          amount: tx['amount'] as int,
                          icon: tx['icon'] as IconData,
                          onLongPress: () => _confirmDelete(globalIndex),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // FAB to add a new transaction
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add', style: AppTextStyles.button),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: AppTextStyles.subHeading.copyWith(
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first one',
            style: AppTextStyles.body.copyWith(color: Colors.white30),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet to quickly add a new transaction.
  void _showAddTransactionSheet(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    bool isExpense = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  color: const Color(0xFF1E293B),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Add Transaction', style: AppTextStyles.subHeading),
                      const SizedBox(height: 20),

                      // Income / Expense toggle
                      Row(
                        children: [
                          _toggleChip(
                            'Expense',
                            isExpense,
                            AppColors.errorRed,
                            () => setSheetState(() => isExpense = true),
                          ),
                          const SizedBox(width: 10),
                          _toggleChip(
                            'Income',
                            !isExpense,
                            AppColors.successGreen,
                            () => setSheetState(() => isExpense = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: titleController,
                        style: AppTextStyles.body,
                        decoration: _sheetInputDecoration('Description'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.body,
                        decoration: _sheetInputDecoration('Amount (UGX)'),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final title = titleController.text.trim();
                          final parsed = int.tryParse(
                            amountController.text.replaceAll(',', ''),
                          );
                          if (title.isEmpty || parsed == null || parsed <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields correctly'),
                                backgroundColor: AppColors.errorRed,
                              ),
                            );
                            return;
                          }
                          final newTx = {
                            'title': title,
                            'amount': isExpense ? -parsed : parsed,
                            'icon': isExpense
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            'category': 'Other',
                          };
                          setState(() => _localTransactions.insert(0, newTx));
                          widget.onTransactionsChanged(_localTransactions);
                          Navigator.pop(sheetContext);
                        },
                        child: Text('Add Transaction', style: AppTextStyles.button),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _toggleChip(
    String label,
    bool isActive,
    Color activeColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: isActive ? activeColor : Colors.white38,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  InputDecoration _sheetInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.body.copyWith(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
