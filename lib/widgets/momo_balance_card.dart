import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/ussd_service.dart';
import '../services/finance_store.dart';

/// MoMo Balance Card widget.
/// Calls [onBalanceSaved] after a successful USSD check so the parent
/// (HomeScreen) can refresh the SafeToSpendCard immediately.
class MomoBalanceCard extends StatefulWidget {
  final VoidCallback? onBalanceSaved;
  const MomoBalanceCard({super.key, this.onBalanceSaved});

  @override
  State<MomoBalanceCard> createState() => _MomoBalanceCardState();
}

class _MomoBalanceCardState extends State<MomoBalanceCard> {
  // ── State ─────────────────────────────────────────────────────────────────
  int? _balance;                          // null = not yet checked
  bool _balanceVisible = true;            // eye toggle
  bool _isLoading = false;                // waiting for USSD response
  String? _errorMessage;
  DateTime? _lastChecked;
  Telecom _selectedTelecom = Telecom.mtnUganda;

  // ── Format helpers ────────────────────────────────────────────────────────
  String _formatBalance(int amount) {
    return amount
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final now = DateTime.now();
    final isToday = dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
    return isToday ? 'Today, $h:$m' : '${dt.day}/${dt.month}, $h:$m';
  }

  // ── PIN dialog ────────────────────────────────────────────────────────────
  Future<String?> _showPinDialog() async {
    final pinController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _telecomColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_telecomIcon, color: _telecomColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Check Balance',
                style: AppTextStyles.subHeading,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your ${UssdService.telecomName(_selectedTelecom)} '
              'PIN to check your wallet balance.',
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 5,
              style: AppTextStyles.body.copyWith(
                fontSize: 22,
                letterSpacing: 8,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                counterText: '',
                hintText: '• • • •',
                hintStyle: AppTextStyles.body.copyWith(
                  fontSize: 22,
                  letterSpacing: 8,
                  color: Colors.white24,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _telecomColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '🔒 Your PIN is used only to form the USSD request '
              'and is never stored.',
              style: AppTextStyles.body.copyWith(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              'Cancel',
              style: AppTextStyles.body.copyWith(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _telecomColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, pinController.text.trim()),
            child: const Text(
              'Check Balance',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main action: show PIN dialog then send USSD ───────────────────────────
  Future<void> _checkBalance() async {
    if (_isLoading) return;

    final pin = await _showPinDialog();
    if (pin == null || pin.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // For MTN Uganda the full USSD with PIN is *165*5*1*{PIN}#
    // For Airtel it varies — we use the base code and the network handles PIN
    // via the standard USSD session. Override the code here if needed.
    final customCode = _selectedTelecom == Telecom.mtnUganda
        ? '*165*5*1*$pin#'
        : '*185*$pin#';

    // We bypass UssdService.checkBalance to inject the PIN-embedded code
    final result = await _sendCustomUssd(customCode);

    if (mounted) {
      if (result.isSuccess) {
        // Persist to FinanceStore so SafeToSpendCard can read it
        await FinanceStore.saveMomoBalance(
          balance: result.balanceUgx!,
          telecom: _selectedTelecom == Telecom.mtnUganda ? 'mtn' : 'airtel',
        );
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.isSuccess) {
            _balance = result.balanceUgx;
            _lastChecked = DateTime.now();
            _errorMessage = null;
            _balanceVisible = true;
          } else {
            _errorMessage = result.error;
          }
        });
        // Tell parent to refresh the safe-to-spend card
        if (result.isSuccess) widget.onBalanceSaved?.call();
      }
    }
  }

  Future<UssdBalanceResult> _sendCustomUssd(String ussdCode) async {
    // Re-use the service but send our custom code directly
    // We call checkPermission first then sendUssd with our code
    final hasPermission = await UssdService.hasPermission();
    if (!hasPermission) {
      final granted = await UssdService.requestPermission();
      if (!granted) {
        return const UssdBalanceResult(
          rawResponse: '',
          error: 'Phone permission denied. Please allow it in Settings → Apps → SmartFinance AI → Permissions.',
        );
      }
    }

    // Now use the channel directly with our PIN-embedded code
    try {
      const channel = MethodChannel('com.smartfinance.ussd/balance');
      final raw = await channel
          .invokeMethod<String>('sendUssd', {'ussdCode': ussdCode})
          .timeout(
            const Duration(seconds: 18),
            onTimeout: () => throw Exception(
              'No response from network after 18 seconds. '
              'Check your signal strength and try again.',
            ),
          );

      if (raw == null || raw.isEmpty) {
        return const UssdBalanceResult(
          rawResponse: '',
          error: 'Network returned an empty response.',
        );
      }

      // Try to parse balance from the raw response
      final balanceMatch = RegExp(
        r'UGX\s*([\d,]+)',
        caseSensitive: false,
      ).firstMatch(raw);

      if (balanceMatch != null) {
        final cleaned = balanceMatch.group(1)!.replaceAll(',', '');
        final amount = int.tryParse(cleaned);
        return UssdBalanceResult(rawResponse: raw, balanceUgx: amount);
      }

      // Fallback: look for any number after "balance"
      final fallbackMatch = RegExp(
        r'balance[^\d]*([\d,]+)',
        caseSensitive: false,
      ).firstMatch(raw);

      if (fallbackMatch != null) {
        final cleaned = fallbackMatch.group(1)!.replaceAll(',', '');
        final amount = int.tryParse(cleaned);
        return UssdBalanceResult(rawResponse: raw, balanceUgx: amount);
      }

      return UssdBalanceResult(
        rawResponse: raw,
        error: 'Balance received but could not be read. Raw: "$raw"',
      );
    } on PlatformException catch (e) {
      String msg;
      switch (e.code) {
        case 'UNSUPPORTED':
          msg = 'This feature needs Android 8.0+.';
          break;
        case 'PERMISSION_DENIED':
          msg = 'Permission denied. Allow phone calls in Settings.';
          break;
        case 'USSD_FAILED':
          msg = 'Network rejected request. Check your SIM and signal.';
          break;
        default:
          msg = e.message ?? 'Unexpected error occurred.';
      }
      return UssdBalanceResult(rawResponse: '', error: msg);
    } catch (e) {
      return UssdBalanceResult(rawResponse: '', error: e.toString());
    }
  }

  // ── Telecom theme helpers ─────────────────────────────────────────────────
  Color get _telecomColor => _selectedTelecom == Telecom.mtnUganda
      ? const Color(0xFFFFCC00)   // MTN yellow
      : const Color(0xFFE4002B);  // Airtel red

  IconData get _telecomIcon => _selectedTelecom == Telecom.mtnUganda
      ? Icons.signal_cellular_alt
      : Icons.sim_card;

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _telecomColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ───────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Telecom selector
                  _TelecomSelector(
                    selected: _selectedTelecom,
                    onChanged: (t) => setState(() {
                      _selectedTelecom = t;
                      _balance = null;
                      _errorMessage = null;
                      _lastChecked = null;
                    }),
                  ),

                  // Eye toggle (only when balance is known)
                  if (_balance != null)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _balanceVisible = !_balanceVisible),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _balanceVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white54,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Balance display ──────────────────────────────────────
              if (_isLoading)
                _buildLoadingState()
              else if (_errorMessage != null)
                _buildErrorState()
              else if (_balance != null)
                _buildBalanceDisplay()
              else
                _buildEmptyState(),

              const SizedBox(height: 16),

              // ── Refresh button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(
                    Icons.refresh,
                    color: _isLoading ? Colors.white38 : Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    _balance == null ? 'Check Balance' : 'Refresh Balance',
                    style: AppTextStyles.button.copyWith(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading
                        ? Colors.white12
                        : _telecomColor.withValues(alpha: 0.85),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _checkBalance,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${UssdService.telecomName(_selectedTelecom)} Wallet',
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _balanceVisible
                  ? 'UGX ${_formatBalance(_balance!)}'
                  : 'UGX ••••••',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: _telecomColor,
                letterSpacing: _balanceVisible ? 0 : 4,
              ),
            ),
          ],
        ),
        if (_lastChecked != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 11,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 4),
              Text(
                'Last checked: ${_formatTime(_lastChecked!)}',
                style: AppTextStyles.body.copyWith(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _telecomColor,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Contacting ${UssdService.telecomName(_selectedTelecom)}...',
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.errorRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: AppColors.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${UssdService.telecomName(_selectedTelecom)} Wallet',
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tap "Check Balance" to see your wallet amount',
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

// ── Telecom selector chip row ─────────────────────────────────────────────────
class _TelecomSelector extends StatelessWidget {
  final Telecom selected;
  final ValueChanged<Telecom> onChanged;

  const _TelecomSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip(Telecom.mtnUganda, 'MTN', const Color(0xFFFFCC00)),
        const SizedBox(width: 8),
        _chip(Telecom.airtelUganda, 'Airtel', const Color(0xFFE4002B)),
      ],
    );
  }

  Widget _chip(Telecom telecom, String label, Color color) {
    final isSelected = selected == telecom;
    return GestureDetector(
      onTap: () => onChanged(telecom),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            color: isSelected ? color : Colors.white38,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
