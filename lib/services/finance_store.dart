import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A committed expense item the user has declared
/// (e.g. "Rent — UGX 300,000").
class CommittedExpense {
  final String id;      // unique identifier
  final String name;    // e.g. "Rent"
  final int amount;     // in UGX

  const CommittedExpense({
    required this.id,
    required this.name,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
      };

  factory CommittedExpense.fromJson(Map<String, dynamic> j) =>
      CommittedExpense(
        id: j['id'] as String,
        name: j['name'] as String,
        amount: j['amount'] as int,
      );
}

/// Central persistent store for SmartFinance AI.
///
/// All data lives in SharedPreferences — no backend, works offline.
///
/// Keys stored:
///   momo_balance          int
///   momo_telecom          String ('mtn' | 'airtel')
///   momo_checked_at       String (ISO 8601)
///   committed_expenses    String (JSON array)
///   daily_spending_YYYY-MM-DD   int  (resets automatically each new day)
class FinanceStore {
  // ── SharedPreferences keys ──────────────────────────────────────────────
  static const _kBalance      = 'momo_balance';
  static const _kTelecom      = 'momo_telecom';
  static const _kCheckedAt    = 'momo_checked_at';
  static const _kCommitted    = 'committed_expenses';

  static String _dailyKey(DateTime date) =>
      'daily_spending_${date.year.toString().padLeft(4, '0')}'
      '-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';

  // ── Singleton ───────────────────────────────────────────────────────────
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _p {
    assert(_prefs != null, 'FinanceStore.init() must be called first');
    return _prefs!;
  }

  // ── MoMo balance ────────────────────────────────────────────────────────

  static Future<void> saveMomoBalance({
    required int balance,
    required String telecom, // 'mtn' or 'airtel'
  }) async {
    await _p.setInt(_kBalance, balance);
    await _p.setString(_kTelecom, telecom);
    await _p.setString(_kCheckedAt, DateTime.now().toIso8601String());
  }

  /// Returns null if balance has never been checked.
  static int? getMomoBalance() => _p.getInt(_kBalance);

  static String getMomoTelecom() => _p.getString(_kTelecom) ?? 'mtn';

  /// Returns null if never checked.
  static DateTime? getCheckedAt() {
    final raw = _p.getString(_kCheckedAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  /// Human-readable "X minutes/hours ago" string.
  static String getCheckedAtLabel() {
    final dt = getCheckedAt();
    if (dt == null) return 'Never checked';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Committed expenses ──────────────────────────────────────────────────

  static List<CommittedExpense> getCommittedExpenses() {
    final raw = _p.getString(_kCommitted);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CommittedExpense.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCommittedExpenses(
    List<CommittedExpense> expenses,
  ) async {
    final encoded = jsonEncode(expenses.map((e) => e.toJson()).toList());
    await _p.setString(_kCommitted, encoded);
  }

  static Future<void> addCommittedExpense(CommittedExpense expense) async {
    final list = getCommittedExpenses()..add(expense);
    await saveCommittedExpenses(list);
  }

  static Future<void> removeCommittedExpense(String id) async {
    final list = getCommittedExpenses()..removeWhere((e) => e.id == id);
    await saveCommittedExpenses(list);
  }

  /// Total UGX committed to planned expenses.
  static int getTotalCommitted() =>
      getCommittedExpenses().fold(0, (sum, e) => sum + e.amount);

  // ── Daily spending ──────────────────────────────────────────────────────

  /// Returns how much has been logged as spent today.
  static int getTodaySpending() {
    return _p.getInt(_dailyKey(DateTime.now())) ?? 0;
  }

  /// Add [amount] to today's spending total.
  static Future<void> addTodaySpending(int amount) async {
    final current = getTodaySpending();
    await _p.setInt(_dailyKey(DateTime.now()), current + amount);
  }

  /// Override today's total directly (for corrections).
  static Future<void> setTodaySpending(int amount) async {
    await _p.setInt(_dailyKey(DateTime.now()), amount);
  }

  /// Returns spending for a specific date (0 if none recorded).
  static int getSpendingForDate(DateTime date) =>
      _p.getInt(_dailyKey(date)) ?? 0;

  // ── Core calculations ───────────────────────────────────────────────────

  /// MoMo balance − all committed expenses = free balance.
  /// Returns null if MoMo balance has not been checked yet.
  static int? getFreeBalance() {
    final balance = getMomoBalance();
    if (balance == null) return null;
    return balance - getTotalCommitted();
  }

  /// Free balance − today's spending = safe to spend right now.
  /// Returns null if MoMo balance has not been checked yet.
  static int? getSafeToSpend() {
    final free = getFreeBalance();
    if (free == null) return null;
    return free - getTodaySpending();
  }

  // ── Chart data: last 7 days of spending ────────────────────────────────

  /// Returns a list of 7 entries: [{date, spending, freeBalance}]
  /// starting 6 days ago through today.
  static List<Map<String, dynamic>> getLast7DaysData() {
    final today = DateTime.now();
    final momoBalance = getMomoBalance();
    final committed = getTotalCommitted();

    return List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      final spending = getSpendingForDate(date);
      // Simulated running free balance for chart:
      // starts at (momoBalance - committed) and we show daily spend on top
      final free = momoBalance != null ? momoBalance - committed : 0;
      return {
        'date': date,
        'spending': spending,
        'freeBalance': free,
        'dayLabel': _shortDay(date.weekday),
      };
    });
  }

  static String _shortDay(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  // ── Full reset (for testing / logout) ──────────────────────────────────
  static Future<void> clearAll() async => _p.clear();
}
