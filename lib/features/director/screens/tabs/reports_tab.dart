import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/tea_entry.dart';
import '../../../../core/providers/auth_providers.dart';

// ---------------------------------------------------------------------------
// Local data classes
// ---------------------------------------------------------------------------

class _WorkerPerf {
  final String workerId;
  final String workerName;
  final double totalKg;
  final double totalAmount;
  final double fraction;

  const _WorkerPerf({
    required this.workerId,
    required this.workerName,
    required this.totalKg,
    required this.totalAmount,
    required this.fraction,
  });
}

class _ChartData {
  final List<double> values;
  final List<String> labels;
  final int highlightIndex;

  const _ChartData({
    required this.values,
    required this.labels,
    required this.highlightIndex,
  });

  bool get isEmpty => values.isEmpty;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kPeriodLabels = ['Today', 'This Week', 'This Month'];

String _fmtKgR(double kg) {
  if (kg == 0) return '0 kg';
  if (kg >= 1000) return '${(kg / 1000).toStringAsFixed(1)}t';
  return '${kg.toStringAsFixed(1)} kg';
}

String _fmtAmtR(double amount) {
  if (amount >= 1000000) {
    return 'Rs ${(amount / 1000000).toStringAsFixed(2)}M';
  }
  if (amount >= 1000) return 'Rs ${(amount / 1000).toStringAsFixed(1)}K';
  return 'Rs ${amount.toStringAsFixed(0)}';
}

DateTime? _parseDate(String s) => DateTime.tryParse(s);

String _todayStrR() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

String _monthPfxR() {
  final n = DateTime.now();
  return '${n.year}-${n.month.toString().padLeft(2, '0')}';
}

const _kDayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

// ---------------------------------------------------------------------------
// ReportsTab
// ---------------------------------------------------------------------------

class ReportsTab extends ConsumerStatefulWidget {
  const ReportsTab({super.key});

  @override
  ConsumerState<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<ReportsTab> {
  int _periodIndex = 1; // default: This Week

  @override
  Widget build(BuildContext context) {
    final estate = ref.watch(estateNotifierProvider);
    final allEntriesAsync = estate != null
        ? ref.watch(teaEntriesProvider((estate.estateId, null)))
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(allEntriesAsync),
      body: allEntriesAsync == null
          ? Center(
              child: Text(
                'No estate selected.',
                style: GoogleFonts.dmSans(color: AppColors.textHint),
              ),
            )
          : allEntriesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => Center(
                child: Text(
                  'Failed to load report data.',
                  style: GoogleFonts.dmSans(color: AppColors.textHint),
                ),
              ),
              data: (allEntries) => _buildBody(allEntries),
            ),
    );
  }

  // -------------------------------------------------------------------------
  // Body
  // -------------------------------------------------------------------------

  Widget _buildBody(List<TeaEntry> allEntries) {
    final now = DateTime.now();
    final today = _todayStrR();
    final monthPfx = _monthPfxR();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));

    final periodEntries = _filterByPeriod(allEntries, now, today, monthPfx, weekStart);

    final totalKg = periodEntries.fold(0.0, (s, e) => s + e.kg);
    final totalAmount = periodEntries.fold(0.0, (s, e) => s + e.totalAmount);
    final uniqueWorkers = periodEntries.map((e) => e.workerId).toSet().length;
    final avgPerWorker = uniqueWorkers > 0 ? totalKg / uniqueWorkers : 0.0;

    final chartData = _buildChartData(periodEntries, now, weekStart);
    final workerRanking = _buildWorkerRanking(periodEntries);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(teaEntriesProvider),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodChips(),
            const SizedBox(height: 16),
            _buildSummaryRow(totalKg, totalAmount, avgPerWorker),
            const SizedBox(height: 24),
            _buildChartSection(chartData, now),
            const SizedBox(height: 24),
            _buildWorkerSection(workerRanking),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Data helpers
  // -------------------------------------------------------------------------

  List<TeaEntry> _filterByPeriod(
    List<TeaEntry> all,
    DateTime now,
    String today,
    String monthPfx,
    DateTime weekStart,
  ) {
    switch (_periodIndex) {
      case 0:
        return all.where((e) => e.date == today).toList();
      case 1:
        return all.where((e) {
          final d = _parseDate(e.date);
          if (d == null) return false;
          final dateOnly = DateTime(d.year, d.month, d.day);
          return !dateOnly.isBefore(weekStart) &&
              !dateOnly.isAfter(DateTime(now.year, now.month, now.day));
        }).toList();
      default:
        return all.where((e) => e.date.startsWith(monthPfx)).toList();
    }
  }

  _ChartData _buildChartData(
    List<TeaEntry> entries,
    DateTime now,
    DateTime weekStart,
  ) {
    if (entries.isEmpty) {
      return const _ChartData(values: [], labels: [], highlightIndex: 0);
    }

    switch (_periodIndex) {
      case 0: // Today — top 8 workers by total kg
        final Map<String, double> workerKg = {};
        for (final e in entries) {
          workerKg[e.workerName] = (workerKg[e.workerName] ?? 0) + e.kg;
        }
        final sorted = workerKg.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top = sorted.take(8).toList();
        final values = top.map((e) => e.value).toList();
        final labels = top.map((e) => e.key.split(' ').first).toList();
        final hi = values.indexOf(values.reduce(math.max));
        return _ChartData(values: values, labels: labels, highlightIndex: hi);

      case 1: // This Week — total kg per weekday Mon–Sun
        final values = List.filled(7, 0.0);
        for (final e in entries) {
          final d = _parseDate(e.date);
          if (d == null) continue;
          values[d.weekday - 1] += e.kg;
        }
        final hi = now.weekday - 1; // highlight today
        return _ChartData(
            values: values,
            labels: List.from(_kDayNames),
            highlightIndex: hi);

      default: // This Month — total kg per week (Wk 1–4+)
        final Map<int, double> weekKg = {};
        for (final e in entries) {
          final d = _parseDate(e.date);
          if (d == null) continue;
          final wk = (d.day - 1) ~/ 7;
          weekKg[wk] = (weekKg[wk] ?? 0) + e.kg;
        }
        final maxWk = weekKg.keys.reduce(math.max);
        final values = List.generate(maxWk + 1, (i) => weekKg[i] ?? 0.0);
        final labels = List.generate(maxWk + 1, (i) => 'Wk ${i + 1}');
        final hi = ((now.day - 1) ~/ 7).clamp(0, values.length - 1);
        return _ChartData(values: values, labels: labels, highlightIndex: hi);
    }
  }

  List<_WorkerPerf> _buildWorkerRanking(List<TeaEntry> entries) {
    final Map<String, (String, double, double)> totals = {};
    for (final e in entries) {
      final ex = totals[e.workerId];
      totals[e.workerId] = ex == null
          ? (e.workerName, e.kg, e.totalAmount)
          : (ex.$1, ex.$2 + e.kg, ex.$3 + e.totalAmount);
    }

    final sorted = totals.entries
        .map((me) => _WorkerPerf(
              workerId: me.key,
              workerName: me.value.$1,
              totalKg: me.value.$2,
              totalAmount: me.value.$3,
              fraction: 1.0,
            ))
        .toList()
      ..sort((a, b) => b.totalKg.compareTo(a.totalKg));

    if (sorted.isEmpty) return [];
    final maxKg = sorted.first.totalKg;
    return sorted
        .take(5)
        .map((w) => _WorkerPerf(
              workerId: w.workerId,
              workerName: w.workerName,
              totalKg: w.totalKg,
              totalAmount: w.totalAmount,
              fraction: maxKg > 0 ? w.totalKg / maxKg : 0,
            ))
        .toList();
  }

  // -------------------------------------------------------------------------
  // UI builders
  // -------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(AsyncValue<List<TeaEntry>>? async) {
    return AppBar(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Reports',
        style: GoogleFonts.playfairDisplay(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (async != null)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => ref.invalidate(teaEntriesProvider),
            tooltip: 'Refresh',
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  Widget _buildPeriodChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: List.generate(_kPeriodLabels.length, (i) {
          final selected = i == _periodIndex;
          return Padding(
            padding:
                EdgeInsets.only(right: i < _kPeriodLabels.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _periodIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _kPeriodLabels[i],
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryRow(
      double totalKg, double totalAmount, double avgPerWorker) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.eco_rounded,
            label: 'Total Harvest',
            value: _fmtKgR(totalKg),
            iconBg: AppColors.primaryFaint,
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.currency_rupee_rounded,
            label: 'Revenue',
            value: _fmtAmtR(totalAmount),
            iconBg: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFB7943A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.speed_rounded,
            label: 'Avg / Worker',
            value: '${avgPerWorker.toStringAsFixed(1)} kg',
            iconBg: const Color(0xFFEDE7F6),
            iconColor: const Color(0xFF6A1B9A),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(_ChartData data, DateTime now) {
    const maxBarHeight = 140.0;

    final chartTitle = switch (_periodIndex) {
      0 => 'Top Workers Today',
      1 => 'Daily Harvest This Week',
      _ => 'Weekly Harvest This Month',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                chartTitle,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _kPeriodLabels[_periodIndex],
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (data.isEmpty)
            SizedBox(
              height: maxBarHeight,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart_rounded,
                        size: 36,
                        color: AppColors.textHint.withValues(alpha: 0.35)),
                    const SizedBox(height: 8),
                    Text(
                      'No data for this period',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SizedBox(
              height: maxBarHeight + 30,
              child: Builder(builder: (context) {
                final maxVal = data.values.reduce(math.max);
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(data.values.length, (i) {
                    final ratio = maxVal > 0 ? data.values[i] / maxVal : 0.0;
                    final isHi = i == data.highlightIndex;
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            key: ValueKey('chart-$_periodIndex-$i'),
                            tween: Tween(begin: 0.0, end: ratio),
                            duration:
                                Duration(milliseconds: 450 + i * 50),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, __) => Container(
                              height:
                                  (v * maxBarHeight).clamp(4.0, maxBarHeight),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: isHi
                                    ? AppColors.primary
                                    : AppColors.primaryLight
                                        .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data.labels[i],
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              color: isHi
                                  ? AppColors.primary
                                  : AppColors.textHint,
                              fontWeight: isHi
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }),
                );
              }),
            ),
            if (_periodIndex == 1) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  _legendDot(AppColors.primary),
                  const SizedBox(width: 6),
                  Text('Today (${_kDayNames[now.weekday - 1]})',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textHint)),
                  const SizedBox(width: 16),
                  _legendDot(AppColors.primaryLight.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Text('Other days',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textHint)),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      );

  Widget _buildWorkerSection(List<_WorkerPerf> workers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Worker Performance',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: workers.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No harvest entries for this period.',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: AppColors.textHint),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(workers.length, (i) {
                    final isLast = i == workers.length - 1;
                    return Column(
                      children: [
                        _WorkerPerfRow(perf: workers[i], rank: i + 1),
                        if (!isLast)
                          const Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.divider,
                          ),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconBg;
  final Color iconColor;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Worker performance row
// ---------------------------------------------------------------------------

class _WorkerPerfRow extends StatelessWidget {
  final _WorkerPerf perf;
  final int rank;

  const _WorkerPerfRow({required this.perf, required this.rank});

  static const _rankColors = [
    Color(0xFFFFD700), // Gold
    Color(0xFFAAAAAA), // Silver
    Color(0xFFCD7F32), // Bronze
    AppColors.textHint,
    AppColors.textHint,
  ];

  @override
  Widget build(BuildContext context) {
    final idx = math.min(rank - 1, _rankColors.length - 1);
    final rankColor = _rankColors[idx];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: rankColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: rankColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  perf.workerName,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                _fmtKgR(perf.totalKg),
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: perf.fraction,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primaryLight),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                _fmtAmtR(perf.totalAmount),
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                perf.fraction >= 1.0
                    ? 'Top performer'
                    : '${(perf.fraction * 100).toStringAsFixed(0)}% of top',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
