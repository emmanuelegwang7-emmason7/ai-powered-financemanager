import 'package:flutter/services.dart';

/// Supported telecoms — add more here as you test them.
enum Telecom { mtnUganda, airtelUganda }

/// Result returned after a USSD balance check.
class UssdBalanceResult {
  /// The raw response string from the telecom network.
  final String rawResponse;

  /// The parsed balance in UGX (null if parsing failed).
  final int? balanceUgx;

  /// Human-readable error message (null on success).
  final String? error;

  bool get isSuccess => error == null && balanceUgx != null;

  const UssdBalanceResult({
    required this.rawResponse,
    this.balanceUgx,
    this.error,
  });
}

/// Service that bridges Flutter to the native Android USSD platform channel.
///
/// Usage:
/// ```dart
/// final result = await UssdService.checkBalance(Telecom.mtnUganda);
/// if (result.isSuccess) print('Balance: UGX ${result.balanceUgx}');
/// ```
class UssdService {
  // Must match the channel name in MainActivity.kt exactly
  static const _channel = MethodChannel('com.smartfinance.ussd/balance');

  // ── USSD codes per telecom ────────────────────────────────────────────────
  // MTN Uganda balance: *165*5*1# (some handsets use *165# then navigate)
  // Airtel Uganda balance: *185# (enter PIN on USSD menu)
  static const Map<Telecom, String> _ussdCodes = {
    Telecom.mtnUganda: '*165*5*1#',
    Telecom.airtelUganda: '*185#',
  };

  static const Map<Telecom, String> _telecomNames = {
    Telecom.mtnUganda: 'MTN Uganda',
    Telecom.airtelUganda: 'Airtel Uganda',
  };

  // ── Permission helpers ────────────────────────────────────────────────────

  /// Returns true if CALL_PHONE permission is already granted.
  static Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests CALL_PHONE permission from the user.
  /// Returns true if granted.
  static Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Main balance check ────────────────────────────────────────────────────

  /// Sends a USSD request to the given [telecom] and returns a parsed result.
  ///
  /// Automatically requests permission if not already granted.
  /// Times out after [timeoutSeconds] seconds (default 15).
  static Future<UssdBalanceResult> checkBalance(
    Telecom telecom, {
    int timeoutSeconds = 15,
  }) async {
    // 1. Ensure permission
    bool permitted = await hasPermission();
    if (!permitted) {
      permitted = await requestPermission();
      if (!permitted) {
        return const UssdBalanceResult(
          rawResponse: '',
          error: 'CALL_PHONE permission was denied. '
              'Please grant it in your phone Settings.',
        );
      }
    }

    final ussdCode = _ussdCodes[telecom]!;

    try {
      // 2. Send USSD — wait up to [timeoutSeconds]
      final raw = await _channel
          .invokeMethod<String>('sendUssd', {'ussdCode': ussdCode})
          .timeout(
            Duration(seconds: timeoutSeconds),
            onTimeout: () => throw Exception(
              'No response from ${_telecomNames[telecom]} network after '
              '$timeoutSeconds seconds. Check your signal and try again.',
            ),
          );

      if (raw == null || raw.isEmpty) {
        return const UssdBalanceResult(
          rawResponse: '',
          error: 'Received an empty response from the network.',
        );
      }

      // 3. Parse the balance from the response string
      final balance = _parseBalance(raw);
      if (balance == null) {
        return UssdBalanceResult(
          rawResponse: raw,
          error: 'Could not read balance from network response.',
        );
      }

      return UssdBalanceResult(rawResponse: raw, balanceUgx: balance);
    } on PlatformException catch (e) {
      String msg;
      switch (e.code) {
        case 'UNSUPPORTED':
          msg = 'Your Android version is too old for this feature '
              '(requires Android 8.0+).';
          break;
        case 'PERMISSION_DENIED':
          msg = 'Phone permission denied. Please enable it in Settings.';
          break;
        case 'USSD_FAILED':
          msg = 'Network rejected the USSD request. '
              'Make sure you have an active SIM and signal.';
          break;
        default:
          msg = e.message ?? 'An unknown error occurred.';
      }
      return UssdBalanceResult(rawResponse: '', error: msg);
    } catch (e) {
      return UssdBalanceResult(rawResponse: '', error: e.toString());
    }
  }

  // ── Balance parser ────────────────────────────────────────────────────────

  /// Extracts the UGX balance integer from a raw USSD response string.
  ///
  /// Handles common MTN Uganda formats:
  ///   "MoMo balance: UGX 127,450. Expires 31/12/2026."
  ///   "Your balance is UGX 2,500,000"
  ///   "Balance: 50000 UGX"
  ///
  /// Airtel Uganda formats:
  ///   "Airtel Money Balance: UGX 45,200"
  ///   "Your Airtel Money balance is 45200 UGX"
  static int? _parseBalance(String response) {
    // Strategy 1: "UGX" followed by the number (with optional commas)
    final afterUgx = RegExp(r'UGX\s*([\d,]+)', caseSensitive: false);
    final m1 = afterUgx.firstMatch(response);
    if (m1 != null) {
      return _cleanNumber(m1.group(1)!);
    }

    // Strategy 2: number followed by "UGX"
    final beforeUgx = RegExp(r'([\d,]+)\s*UGX', caseSensitive: false);
    final m2 = beforeUgx.firstMatch(response);
    if (m2 != null) {
      return _cleanNumber(m2.group(1)!);
    }

    // Strategy 3: "balance" keyword near a number
    final nearBalance = RegExp(
      r'balance[^0-9]*([\d,]+)',
      caseSensitive: false,
    );
    final m3 = nearBalance.firstMatch(response);
    if (m3 != null) {
      return _cleanNumber(m3.group(1)!);
    }

    return null; // parsing failed
  }

  static int? _cleanNumber(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    return int.tryParse(cleaned);
  }

  /// Returns the display name of a telecom.
  static String telecomName(Telecom t) => _telecomNames[t]!;
}
