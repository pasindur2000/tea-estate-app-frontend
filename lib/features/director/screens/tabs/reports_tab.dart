import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------

class _ReportPeriod {
  final String label;
  final String totalKg;
  final String revenue;
  final String avgPerWorker;
  final List<double> chartValues;
  final List<String> chartLabels;
  final int highlightIndex;

  const _ReportPeriod({
    required this.label,
    required this.totalKg,
    required this.revenue,
    required this.avgPerWorker,
    required this.chartValues,
    required this.chartLabels,
    required this.highlightIndex,
  });
}

const _periods = [
  _ReportPeriod(
    label: 'Today',
    totalKg: '1,245',
    revenue: 'Rs 12,450',
    avgPerWorker: '5.02 kg',
    chartValues: [95, 145, 198, 215, 210, 192, 165, 25],
    chartLabels: ['6AM', '7AM', '8AM', '9AM', '10AM', '11AM', '12PM', '1PM'],
    highlightIndex: 6,
  ),
  _ReportPeriod(
    label: 'This Week',
    totalKg: '8,640',
    revenue: 'Rs 86,400',
    avgPerWorker: '34.8 kg',
    chartValues: [1100, 1245, 980, 1380, 1150, 1290, 495],
    chartLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    highlightIndex: 1,
  ),
  _ReportPeriod(
    label: 'This Month',
    totalKg: '28,400',
    revenue: 'Rs 2.84M',
    avgPerWorker: '114.5 kg',
    chartValues: [6800, 7200, 7100, 7300],
    chartLabels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'],
    highlightIndex: 3,
  ),
];

class _EstateReport {
  final String name;
  final String harvest;
  final String revenue;
  final int workers;
  final double fraction;

  const _EstateReport({
    required this.name,
    required this.harvest,
    required this.revenue,
    required this.workers,
    required this.fraction,
  });
}

const _estateReports = [
  _EstateReport(
    name: 'Nuwara Eliya Estate',
    harvest: '4,820 kg',
    revenue: 'Rs 48,200',
    workers: 82,
    fraction: 1.0,
  ),
  _EstateReport(
    name: 'Kandy Valley Estate',
    harvest: '3,650 kg',
    revenue: 'Rs 36,500',
    workers: 64,
    fraction: 0.76,
  ),
  _EstateReport(
    name: 'Dimbula Estate',
    harvest: '2,980 kg',
    revenue: 'Rs 29,800',
    workers: 54,
    fraction: 0.62,
  ),
  _EstateReport(
    name: 'Uva Highland Estate',
    harvest: '2,390 kg',
    revenue: 'Rs 23,900',
    workers: 48,
    fraction: 0.50,
  ),
];

// ---------------------------------------------------------------------------
// ReportsTab
// ---------------------------------------------------------------------------

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  int _periodIndex = 1; // default: This Week

  _ReportPeriod get _current => _periods[_periodIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodChips(),
            const SizedBox(height: 16),
            _buildSummaryRow(),
            const SizedBox(height: 24),
            _buildChartSection(),
            const SizedBox(height: 24),
            _buildEstateSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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
        IconButton(
          icon: const Icon(Icons.download_rounded, color: Colors.white),
          onPressed: () {},
          tooltip: 'Export',
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
        children: List.generate(_periods.length, (i) {
          final selected = i == _periodIndex;
          return Padding(
            padding: EdgeInsets.only(right: i < _periods.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _periodIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.border,
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
                  _periods[i].label,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.eco_rounded,
            label: 'Total Harvest',
            value: _current.totalKg,
            unit: 'kg',
            iconBg: AppColors.primaryFaint,
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.currency_rupee_rounded,
            label: 'Revenue',
            value: _current.revenue,
            unit: '',
            iconBg: const Color(0xFFFFF8E1),
            iconColor: const Color(0xFFB7943A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.speed_rounded,
            label: 'Avg / Worker',
            value: _current.avgPerWorker,
            unit: '',
            iconBg: const Color(0xFFEDE7F6),
            iconColor: const Color(0xFF6A1B9A),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    final data = _current;
    final max = data.chartValues.reduce((a, b) => a > b ? a : b);
    const maxBarHeight = 140.0;

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
                'Harvest Trend',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                data.label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: maxBarHeight + 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.chartValues.length, (i) {
                final ratio = data.chartValues[i] / max;
                final isHighlight = i == data.highlightIndex;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TweenAnimationBuilder<double>(
                        key: ValueKey('chart-$_periodIndex-$i'),
                        tween: Tween(begin: 0.0, end: ratio),
                        duration: Duration(milliseconds: 450 + i * 50),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) {
                          return Container(
                            height: (value * maxBarHeight).clamp(4.0, maxBarHeight),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: isHighlight
                                  ? AppColors.primary
                                  : AppColors.primaryLight
                                      .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.chartLabels[i],
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          color: isHighlight
                              ? AppColors.primary
                              : AppColors.textHint,
                          fontWeight: isHighlight
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          if (_periodIndex == 1) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(3),
                    )),
                const SizedBox(width: 6),
                Text('Today (Tue)', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textHint)),
                const SizedBox(width: 16),
                Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(3),
                    )),
                const SizedBox(width: 6),
                Text('Other days', style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEstateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estate Performance',
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
          child: Column(
            children: List.generate(_estateReports.length, (i) {
              final isLast = i == _estateReports.length - 1;
              return Column(
                children: [
                  _EstateRow(report: _estateReports[i], rank: i + 1),
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
  final String unit;
  final Color iconBg;
  final Color iconColor;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
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
// Estate row
// ---------------------------------------------------------------------------

class _EstateRow extends StatelessWidget {
  final _EstateReport report;
  final int rank;

  const _EstateRow({required this.report, required this.rank});

  static const _rankColors = [
    Color(0xFFFFD700),
    Color(0xFFAAAAAA),
    Color(0xFFCD7F32),
    AppColors.textHint,
  ];

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColors[rank - 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rank badge
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
                  report.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                report.harvest,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: report.fraction,
              backgroundColor: Colors.grey.shade100,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                report.revenue,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              const Icon(Icons.people_outline_rounded,
                  size: 12, color: AppColors.textHint),
              const SizedBox(width: 3),
              Text(
                '${report.workers} workers',
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
