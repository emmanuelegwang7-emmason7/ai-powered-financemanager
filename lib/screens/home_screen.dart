import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  // Dynamic collection (Adapter/RecyclerView equivalent)
  final List<Map<String, dynamic>> _transactions = [
    {'title': 'MTN MoMo Airtime', 'amount': -5000, 'icon': Icons.phone_android},
    {'title': 'Salary Credit', 'amount': 2500000, 'icon': Icons.work},
    {'title': 'Uber Ride', 'amount': -12000, 'icon': Icons.directions_car},
    {'title': 'Rolex at Wandegeya', 'amount': -3000, 'icon': Icons.fastfood},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Dashboard', style: AppTextStyles.heading),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GLASSMORPHISM SUMMARY CARD
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.bgGradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Safe-to-Spend Today', style: AppTextStyles.body),
                      const SizedBox(height: 8),
                      Text(
                        'UGX 45,000',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // CHOICE CONTROL: Dropdown (Spinner equivalent)
            Row(
              children: [
                Text('Filter by: ', style: AppTextStyles.body),
                DropdownButton<String>(
                  value: _selectedCategory,
                  dropdownColor: AppColors.bgGradientStart,
                  style: AppTextStyles.body,
                  underline: const SizedBox(),
                  items: _categories
                      .map(
                        (String cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (String? newVal) =>
                      setState(() => _selectedCategory = newVal!),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text('Recent Transactions', style: AppTextStyles.subHeading),
            const SizedBox(height: 16),

            // DYNAMIC LIST: ListView.builder (Adapter equivalent)
            Expanded(
              child: ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary,
                                child: Icon(tx['icon'], color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  tx['title'],
                                  style: AppTextStyles.body,
                                ),
                              ),
                              Text(
                                'UGX ${tx['amount'].abs().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                style: TextStyle(
                                  color: tx['amount'] > 0
                                      ? AppColors.successGreen
                                      : AppColors.errorRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
