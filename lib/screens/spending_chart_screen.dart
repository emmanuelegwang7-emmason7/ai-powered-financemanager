import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';
import '../services/finance_store.dart';

/// 7-Day Spending Trend Screen.
/// Shows two lines:
///   • Actual daily spending (solid blue line)
///   • Planned daily allowance (dashed white line)
///     = Free Balance ÷ 7 days
class SpendingChartScreen extends StatelessWidget {
  const SpendingChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chartData = FinanceStore.getLast7DaysData();
    final freeBalance = FinanceStore.getFreeBalance();
    final momoBalance = FinanceStore.getMomoBalance();

    // Planned daily allowance = free balance spread over 7 days
    final plannedDaily =
        freeBalance != null && freeBalance > 0 ? freeBalance / 7 : 0.0;

    // Build FlSpot lists
    final actualSpots = <FlSpot>[];
    final plannedSpots = <FlSpot>[];

    for (int i = 0; i < chartData.length; i++) {
      final spending = (chartData[i]['spending'] as int).toDouble();
      actualSpots.add(FlSpot(i.toDouble(), spending));
      plannedSpots.add(FlSpot(i.toDouble(), plannedDaily.toDouble()));
    }

    final maxY = ([
              ...actualSpots.map((s) => s.y),
              plannedDaily,
            ].reduce((a, b) => a > b ? a : b) *
            1.3)
        .ceilToDouble();

    final dayLabels =
        chartData.map((d) => d['dayLabel'] as String).toList();

    return Scaffold(
      backgroundColor: AppColors.bgGradientStart,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Spending Trends', style: AppTextStyles.heading),
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
          child: momoBalance == null
              ? _noDataState()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // ── Summary chips ──────────────────────────────────
                    _summaryRow(freeBalance, plannedDaily),
                    const SizedBox(height: 24),

                    // ── Chart card ─────────────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter:
                            ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(
                              16, 24, 16, 16),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white
                                  .withValues(alpha: 0.12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Last 7 Days',
                                  style: AppTextStyles.subHeading
                                      .copyWith(fontSize: 16)),
                              const SizedBox(height: 6),
                              Text(
                                'Actual spend vs planned daily allowance',
                                style: AppTextStyles.body.copyWith(
                                    fontSize: 12,
                                    color: Colors.white38),
                              ),
                              const SizedBox(height: 24),

                              // ── LINE CHART ─────────────────────────
                              SizedBox(
                                height: 220,
                                child: LineChart(
                                  LineChartData(
                                    minX: 0,
                                    maxX: 6,
                                    minY: 0,
                                    maxY: maxY > 0 ? maxY : 10000,
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval:
                                          maxY > 0 ? maxY / 4 : 2500,
                                      getDrawingHorizontalLine: (_) =>
                                          FlLine(
                                        color: Colors.white
                                            .withValues(alpha: 0.07),
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 52,
                                          getTitlesWidget: (v, _) =>
                                              Text(
                                            _shortAmount(v.toInt()),
                                            style: AppTextStyles.body
                                                .copyWith(
                                                    fontSize: 10,
                                                    color:
                                                        Colors.white38),
                                          ),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (v, _) {
                                            final i = v.toInt();
                                            if (i < 0 ||
                                                i >= dayLabels.length) {
                                              return const SizedBox();
                                            }
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      top: 6),
                                              child: Text(
                                                dayLabels[i],
                                                style: AppTextStyles.body
                                                    .copyWith(
                                                        fontSize: 11,
                                                        color: Colors
                                                            .white54),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false),
                                      ),
                                    ),
                                    lineTouchData: LineTouchData(
                                      touchTooltipData:
                                          LineTouchTooltipData(
                                        getTooltipColor: (_) =>
                                            const Color(0xFF1E293B),
                                        getTooltipItems: (spots) =>
                                            spots.map((s) {
                                          final isActual =
                                              s.barIndex == 0;
                                          return LineTooltipItem(
                                            '${isActual ? 'Spent' : 'Planned'}\nUGX ${_fmt(s.y.toInt())}',
                                            TextStyle(
                                              color: isActual
                                                  ? AppColors.primary
                                                  : Colors.white54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    lineBarsData: [
                                      // ── Actual spending line ───────
                                      LineChartBarData(
                                        spots: actualSpots,
                                        isCurved: true,
                                        curveSmoothness: 0.35,
                                        color: AppColors.primary,
                                        barWidth: 3,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (_, __, ___, ____) =>
                                              FlDotCirclePainter(
                                            radius: 4,
                                            color: AppColors.primary,
                                            strokeWidth: 2,
                                            strokeColor: Colors.white,
                                          ),
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: AppColors.primary
                                              .withValues(alpha: 0.12),
                                        ),
                                      ),

                                      // ── Planned allowance line ─────
                                      LineChartBarData(
                                        spots: plannedSpots,
                                        isCurved: false,
                                        color: Colors.white
                                            .withValues(alpha: 0.35),
                                        barWidth: 1.5,
                                        isStrokeCapRound: true,
                                        dashArray: [6, 4],
                                        dotData: const FlDotData(
                                            show: false),
                                        belowBarData:
                                            BarAreaData(show: false),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Legend ─────────────────────────────
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  _legendDot(AppColors.primary, false),
                                  const SizedBox(width: 6),
                                  Text('Actual Spending',
                                      style: AppTextStyles.body.copyWith(
                                          fontSize: 12,
                                          color: Colors.white60)),
                                  const SizedBox(width: 20),
                                  _legendDot(
                                      Colors.white.withValues(alpha: 0.4),
                                      true),
                                  const SizedBox(width: 6),
                                  Text('Daily Allowance',
                                      style: AppTextStyles.body.copyWith(
                                          fontSize: 12,
                                          color: Colors.white60)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Daily breakdown table ──────────────────────────
                    _dailyBreakdownTable(chartData, plannedDaily),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _summaryRow(int? freeBalance, double plannedDaily) {
    return Row(
      children: [
        Expanded(
          child: _summaryChip(
            'Free Balance',
            freeBalance != null ? 'UGX ${_fmt(freeBalance)}' : '—',
            Icons.account_balance_wallet_outlined,
            AppColors.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryChip(
            'Daily Allowance',
            'UGX ${_fmt(plannedDaily.toInt())}',
            Icons.today_outlined,
            AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(label,
              style: AppTextStyles.body
                  .copyWith(fontSize: 11, color: Colors.white38)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _dailyBreakdownTable(
      List<Map<String, dynamic>> data, double plannedDaily) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                      child: Text('Day',
                          style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              color: Colors.white38,
                              fontWeight: FontWeight.bold))),
                  _tableHeader('Spent'),
                  _tableHeader('Planned'),
                  _tableHeader('Status'),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            ...data.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              final spent = d['spending'] as int;
              final isToday = i == 6;
              final over = spent > plannedDaily;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${d['dayLabel']}${isToday ? ' (today)' : ''}',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13,
                              color: isToday
                                  ? Colors.white
                                  : Colors.white60,
                              fontWeight: isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        _tableCell('UGX ${_fmt(spent)}',
                            over ? AppColors.errorRed : Colors.white70),
                        _tableCell(
                            'UGX ${_fmt(plannedDaily.toInt())}',
                            Colors.white38),
                        _tableCell(
                          spent == 0
                              ? '—'
                              : over
                                  ? '↑ Over'
                                  : '✓ OK',
                          spent == 0
                              ? Colors.white24
                              : over
                                  ? AppColors.errorRed
                                  : AppColors.successGreen,
                        ),
                      ],
                    ),
                  ),
                  if (i < data.length - 1)
                    const Divider(height: 1, color: Colors.white10),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader(String label) => SizedBox(
        width: 72,
        child: Text(label,
            textAlign: TextAlign.right,
            style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: Colors.white38,
                fontWeight: FontWeight.bold)),
      );

  Widget _tableCell(String value, Color color) => SizedBox(
        width: 72,
        child: Text(value,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600)),
      );

  Widget _legendDot(Color color, bool dashed) => Container(
        width: 24,
        height: 3,
        decoration: BoxDecoration(
          color: dashed ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(2),
          border: dashed ? Border.all(color: color, width: 1) : null,
        ),
      );

  Widget _noDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart,
              size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No data yet',
              style: AppTextStyles.subHeading
                  .copyWith(color: Colors.white38)),
          const SizedBox(height: 8),
          Text(
            'Check your MoMo balance and log\nsome spending to see your trend.',
            style: AppTextStyles.body
                .copyWith(color: Colors.white24, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _fmt(int v) => v
      .abs()
      .toString()
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _shortAmount(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toString();
  }
}
