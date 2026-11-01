import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';
import '../widgets/reusable_transaction_item.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/app_wide_menu.dart';
import '../widgets/momo_balance_card.dart';
import '../widgets/safe_to_spend_card.dart';
import '../services/finance_store.dart';
import 'login_screen.dart';
import 'todays_plan_screen.dart';
import 'transaction_history_screen.dart';
import 'ai_advisor_screen.dart';
import 'spending_chart_screen.dart';

/// Home / Dashboard Screen — the central hub of SmartFinance AI.
///
/// M2 requirements covered here:
/// • Back button handled sensibly: shows exit confirmation dialog (PopScope)
/// • App-wide menu (PopupMenuButton) via AppWideMenu widget
/// • Dynamic collection with real-time deletion (ReusableTransactionItem + Dialog)
/// • Category filter Dropdown (DropdownButton)
/// • Receives data from Login (userEmail, userName) and passes them onward
class HomeScreen extends StatefulWidget {
  final String userEmail;
  final String userName;

  const HomeScreen({
    super.key,
    required this.userEmail,
    required this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Food',
    'Transport',
    'Bills',
    'Airtime',
  ];

  // Refresh key — increment to force SafeToSpendCard to re-read the store
  int _cardRefreshKey = 0;

  void _refreshCard() => setState(() => _cardRefreshKey++);

  // ★ Dynamic collection — shared across Home and Transaction History
  List<Map<String, dynamic>> _transactions = [
    {
      'title': 'MTN MoMo Airtime',
      'amount': -5000,
      'icon': Icons.phone_android,
      'category': 'Airtime',
    },
    {
      'title': 'Salary Credit',
      'amount': 2500000,
      'icon': Icons.work,
      'category': 'Income',
    },
    {
      'title': 'Uber Ride',
      'amount': -12000,
      'icon': Icons.directions_car,
      'category': 'Transport',
    },
    {
      'title': 'Rolex at Wandegeya',
      'amount': -3000,
      'icon': Icons.fastfood,
      'category': 'Food',
    },
  ];

  // ★ Filter the list based on selected category
  List<Map<String, dynamic>> get _filteredTransactions {    if (_selectedCategory == 'All') return _transactions;
    return _transactions
        .where((tx) =>
            (tx['category'] as String? ?? '').toLowerCase() ==
            _selectedCategory.toLowerCase())
        .toList();
  }

  String _formatAmount(int value) {
    return value
        .abs()
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  // ★ M2: Back button sensibly — show exit confirmation from the root screen
  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.exit_to_app_outlined,
              color: AppColors.errorRed,
            ),
            const SizedBox(width: 10),
            Text('Exit App?', style: AppTextStyles.subHeading),
          ],
        ),
        content: Text(
          'Are you sure you want to exit SmartFinance AI?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'No, Stay',
              style: AppTextStyles.body.copyWith(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Yes, Exit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (shouldExit == true) {
      SystemNavigator.pop(); // gracefully exit the app
    }
    return false; // always return false; we handle exit ourselves
  }

  Future<void> _deleteTransaction(int filteredIndex) async {
    final tx = _filteredTransactions[filteredIndex];
    final globalIndex = _transactions.indexOf(tx);

    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      itemName: tx['title'] as String,
    );

    if (confirmed == true && mounted) {
      setState(() => _transactions.removeAt(globalIndex));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${tx['title']}" removed',
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
              setState(() => _transactions.insert(globalIndex, tx));
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;

    // ★ M2: PopScope handles back button — shows exit dialog instead of closing
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppColors.bgGradientStart,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SmartFinance AI', style: AppTextStyles.subHeading),
              Text(
                'Hi, ${widget.userName.split(' ').first} 👋',
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          actions: [
            // ★ App-wide 3-dot menu (reusable widget)
            AppWideMenu(
              transactions: _transactions,
              onTransactionsChanged: (updated) =>
                  setState(() => _transactions = List.from(updated)),
              userName: widget.userName,
              userEmail: widget.userEmail,
            ),
            // Logout button
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70),
              tooltip: 'Logout',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Smart Safe-to-Spend Card ─────────────────────────────
                  SafeToSpendCard(refreshKey: _cardRefreshKey),

                  const SizedBox(height: 12),

                  // ── MoMo Wallet Balance Card (USSD) ──────────────────────
                  MomoBalanceCard(onBalanceSaved: _refreshCard),

                  const SizedBox(height: 16),

                  // ── Quick Action Buttons ──────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _quickActionButton(
                          Icons.today_outlined,
                          "Today's Plan",
                          () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TodaysPlanScreen(),
                              ),
                            );
                            // Refresh safe-to-spend card on return
                            _refreshCard();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _quickActionButton(
                          Icons.history,
                          'All Transactions',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionHistoryScreen(
                                transactions: _transactions,
                                onTransactionsChanged: (updated) =>
                                    setState(() => _transactions = List.from(updated)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _quickActionButton(
                          Icons.show_chart,
                          'Trends',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SpendingChartScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _quickActionButton(
                          Icons.smart_toy_outlined,
                          'AI Advisor',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AiAdvisorScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Category filter row ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Transactions', style: AppTextStyles.subHeading),
                      Row(
                        children: [
                          Text(
                            'Filter: ',
                            style: AppTextStyles.body.copyWith(fontSize: 13),
                          ),
                          DropdownButton<String>(
                            value: _selectedCategory,
                            dropdownColor: const Color(0xFF1E293B),
                            style: AppTextStyles.body.copyWith(fontSize: 13),
                            underline: const SizedBox(),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white54,
                            ),
                            items: _categories
                                .map(
                                  (cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCategory = val!),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Dynamic transaction list ──────────────────────────────
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No transactions in "$_selectedCategory"',
                              style: AppTextStyles.body.copyWith(
                                color: Colors.white38,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final tx = filtered[index];
                              // Use the reusable widget
                              return ReusableTransactionItem(
                                title: tx['title'] as String,
                                amount: tx['amount'] as int,
                                icon: tx['icon'] as IconData,
                                onLongPress: () => _deleteTransaction(index),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _quickActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontSize: 11,
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
