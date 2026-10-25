import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../screens/ai_advisor_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/transaction_history_screen.dart';
import '../screens/todays_plan_screen.dart';

/// Enum to identify each menu item without magic strings.
enum AppMenuItem {
  todaysPlan,
  transactionHistory,
  aiAdvisor,
  profile,
  settings,
}

/// A reusable [PopupMenuButton] placed in the AppBar of any screen.
/// Pass [userName] and [userEmail] so they can be forwarded to the
/// Profile screen when the user navigates there.
class AppWideMenu extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final Function(List<Map<String, dynamic>>) onTransactionsChanged;
  final String userName;
  final String userEmail;

  const AppWideMenu({
    super.key,
    required this.transactions,
    required this.onTransactionsChanged,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppMenuItem>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
      ),
      onSelected: (AppMenuItem item) => _handleMenuSelection(context, item),
      itemBuilder: (BuildContext context) => [
        _buildMenuItem(
          AppMenuItem.todaysPlan,
          Icons.today_outlined,
          'Today\'s Plan',
        ),
        _buildMenuItem(
          AppMenuItem.transactionHistory,
          Icons.history,
          'Transaction History',
        ),
        _buildMenuItem(
          AppMenuItem.aiAdvisor,
          Icons.smart_toy_outlined,
          'AI Advisor',
        ),
        const PopupMenuDivider(),
        _buildMenuItem(AppMenuItem.profile, Icons.person_outline, 'My Profile'),
        _buildMenuItem(AppMenuItem.settings, Icons.settings_outlined, 'Settings'),
      ],
    );
  }

  PopupMenuItem<AppMenuItem> _buildMenuItem(
    AppMenuItem value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem<AppMenuItem>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.body),
        ],
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, AppMenuItem item) {
    switch (item) {
      case AppMenuItem.todaysPlan:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TodaysPlanScreen()),
        );
        break;

      case AppMenuItem.transactionHistory:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionHistoryScreen(
              transactions: transactions,
              onTransactionsChanged: onTransactionsChanged,
            ),
          ),
        );
        break;

      case AppMenuItem.aiAdvisor:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiAdvisorScreen()),
        );
        break;

      case AppMenuItem.profile:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              userName: userName,
              userEmail: userEmail,
            ),
          ),
        );
        break;

      case AppMenuItem.settings:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
    }
  }
}
