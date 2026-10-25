import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Today's Plan Screen — satisfies the M2 "Validate every form fully and
/// give feedback" requirement with a second non-login form.
class TodaysPlanScreen extends StatefulWidget {
  const TodaysPlanScreen({super.key});

  @override
  State<TodaysPlanScreen> createState() => _TodaysPlanScreenState();
}

class _TodaysPlanScreenState extends State<TodaysPlanScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for each form field
  final _budgetController = TextEditingController();
  final _savingsGoalController = TextEditingController();
  final _noteController = TextEditingController();

  // Slider value for spending confidence
  double _confidenceLevel = 3;

  // Currently saved plan summary (shown after saving)
  Map<String, String>? _savedPlan;

  @override
  void dispose() {
    _budgetController.dispose();
    _savingsGoalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleSavePlan() {
    // Trigger full form validation
    if (_formKey.currentState!.validate()) {
      // Store the plan so the UI updates
      setState(() {
        _savedPlan = {
          'budget': _budgetController.text,
          'savings': _savingsGoalController.text,
          'note': _noteController.text.isEmpty ? '—' : _noteController.text,
          'confidence': _confidenceLevel.round().toString(),
        };
      });

      // Give clear positive feedback via SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Plan saved! Stay focused today 💪',
                style: AppTextStyles.body.copyWith(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,

      // Back button sensibly navigates back to HomeScreen
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Today's Plan", style: AppTextStyles.heading),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ── Section header ──────────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.today, color: Colors.white70, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Set your financial goals for today',
                        style: AppTextStyles.subHeading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Glassmorphic form card ───────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Daily budget field ──────────────────────────
                            _buildFieldLabel(
                              Icons.account_balance_wallet_outlined,
                              'Daily Budget (UGX)',
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _budgetController,
                              keyboardType: TextInputType.number,
                              style: AppTextStyles.body,
                              decoration: _inputDecoration('e.g. 50000'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your daily budget';
                                }
                                final parsed = int.tryParse(
                                  value.replaceAll(',', ''),
                                );
                                if (parsed == null || parsed <= 0) {
                                  return 'Enter a valid positive amount';
                                }
                                if (parsed > 100000000) {
                                  return 'Amount seems too high — check again';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // ── Savings goal field ──────────────────────────
                            _buildFieldLabel(
                              Icons.savings_outlined,
                              'Savings Goal (UGX)',
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _savingsGoalController,
                              keyboardType: TextInputType.number,
                              style: AppTextStyles.body,
                              decoration: _inputDecoration('e.g. 20000'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your savings goal';
                                }
                                final parsed = int.tryParse(
                                  value.replaceAll(',', ''),
                                );
                                if (parsed == null || parsed < 0) {
                                  return 'Enter a valid amount (0 or more)';
                                }
                                // Savings can't exceed budget
                                final budget = int.tryParse(
                                  _budgetController.text.replaceAll(',', ''),
                                );
                                if (budget != null && parsed > budget) {
                                  return 'Savings goal can\'t exceed daily budget';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // ── Note / focus field ──────────────────────────
                            _buildFieldLabel(
                              Icons.notes_outlined,
                              'Focus Note (optional)',
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _noteController,
                              maxLines: 2,
                              style: AppTextStyles.body,
                              decoration: _inputDecoration(
                                'e.g. Avoid impulse buying today',
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Confidence slider ───────────────────────────
                            _buildFieldLabel(
                              Icons.trending_up,
                              'Confidence Level: ${_confidenceLevel.round()}/5',
                            ),
                            Slider(
                              value: _confidenceLevel,
                              min: 1,
                              max: 5,
                              divisions: 4,
                              label: _confidenceLevel.round().toString(),
                              activeColor: AppColors.primary,
                              inactiveColor: Colors.white24,
                              onChanged: (double val) =>
                                  setState(() => _confidenceLevel = val),
                            ),

                            const SizedBox(height: 28),

                            // ── Save button ─────────────────────────────────
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.save_outlined,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Save Plan',
                                style: AppTextStyles.button,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _handleSavePlan,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Saved Plan Summary Card (shown after saving) ─────────────
                if (_savedPlan != null) ...[
                  const SizedBox(height: 24),
                  _buildSavedPlanSummary(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the plan summary card that appears after a successful save.
  Widget _buildSavedPlanSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.successGreen,
              ),
              const SizedBox(width: 8),
              Text(
                "Today's Active Plan",
                style: AppTextStyles.subHeading.copyWith(
                  color: AppColors.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _summaryRow('💰 Daily Budget', 'UGX ${_savedPlan!['budget']}'),
          _summaryRow('🎯 Savings Goal', 'UGX ${_savedPlan!['savings']}'),
          _summaryRow('📝 Focus Note', _savedPlan!['note']!),
          _summaryRow(
            '💪 Confidence',
            '${_savedPlan!['confidence']}/5',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable row label for form fields.
  Widget _buildFieldLabel(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 18),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Shared input decoration to keep field styling consistent.
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.body.copyWith(
        color: Colors.white30,
        fontSize: 14,
      ),
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
      errorStyle: const TextStyle(color: AppColors.errorRed),
    );
  }
}
