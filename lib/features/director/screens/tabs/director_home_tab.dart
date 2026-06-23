import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/tea_entry.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/weather_section.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _monthPrefix() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

String _fmtKg(double kg) {
  if (kg >= 1000) return '${(kg / 1000).toStringAsFixed(1)}t';
  return '${kg.toStringAsFixed(1)} kg';
}

String _fmtAmount(double amount) {
  if (amount >= 1000000) return 'Rs ${(amount / 1000000).toStringAsFixed(2)}M';
  if (amount >= 1000) return 'Rs ${(amount / 1000).toStringAsFixed(1)}K';
  return 'Rs ${amount.toStringAsFixed(0)}';
}

String _fmtEntryDate(String dateStr) {
  final parts = dateStr.split('-');
  if (parts.length != 3) return dateStr;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (m == null || m < 1 || m > 12 || d == null) return dateStr;
  return '$d ${months[m - 1]}';
}

// ---------------------------------------------------------------------------
// DirectorHomeTab
// ---------------------------------------------------------------------------

class DirectorHomeTab extends ConsumerWidget {
  final VoidCallback? onViewReports;
  final VoidCallback? onViewWorkers;

  const DirectorHomeTab({super.key, this.onViewReports, this.onViewWorkers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estate = ref.watch(estateNotifierProvider);

    final workersAsync = estate != null
        ? ref.watch(workersProvider(estate.estateId))
        : null;

    final allEntriesAsync = estate != null
        ? ref.watch(teaEntriesProvider((estate.estateId, null)))
        : null;

    // Derived stats from tea entries
    final today = _todayStr();
    final monthPfx = _monthPrefix();

    final allEntries = allEntriesAsync?.valueOrNull ?? [];
    final todayEntries = allEntries.where((e) => e.date == today).toList();
    final monthEntries = allEntries
        .where((e) => e.date.startsWith(monthPfx))
        .toList();

    // Top 5 by kg for display only — totals still use the full list
    final topTodayEntries = (List<TeaEntry>.from(todayEntries)
          ..sort((a, b) => b.kg.compareTo(a.kg)))
        .take(5)
        .toList();

    final todayKg = todayEntries.fold(0.0, (s, e) => s + e.kg);
    final monthKg = monthEntries.fold(0.0, (s, e) => s + e.kg);
    final monthEarnings = monthEntries.fold(0.0, (s, e) => s + e.totalAmount);

    String entryVal(AsyncValue<List<TeaEntry>>? async, String computed) {
      if (async == null) return '--';
      return async.when(
        data: (_) => computed,
        loading: () => '…',
        error: (_, __) => '--',
      );
    }

    final totalWorkersVal = workersAsync == null
        ? '--'
        : workersAsync.when(
            data: (l) => '${l.length}',
            loading: () => '…',
            error: (_, __) => '--',
          );

    return SingleChildScrollView(
      child: Column(
        children: [
          const _DashboardHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (estate != null) ...[
                  const SizedBox(height: 20),
                  WeatherSection(location: estate.location),
                ],
                _buildStatsGrid(
                  totalWorkers: totalWorkersVal,
                  todayHarvest: entryVal(allEntriesAsync, _fmtKg(todayKg)),
                  monthKg: entryVal(allEntriesAsync, _fmtKg(monthKg)),
                  monthEarnings: entryVal(
                    allEntriesAsync,
                    _fmtAmount(monthEarnings),
                  ),
                ),
                const SizedBox(height: 35),
                const _SectionHeader(title: 'Quick Actions'),
                _buildQuickActionsGrid(context),
                const SizedBox(height: 35),
                _SectionHeader(
                  title: "Today's Harvest",
                  showSeeAll: onViewReports != null,
                  onSeeAll: onViewReports,
                ),
                const SizedBox(height: 16),
                _TodayHarvestCard(
                  allEntriesAsync: allEntriesAsync,
                  todayEntries: topTodayEntries,
                  totalTodayEntries: todayEntries.length,
                  todayStr: today,
                  onViewWorkers: onViewWorkers,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid({
    required String totalWorkers,
    required String todayHarvest,
    required String monthKg,
    required String monthEarnings,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.45,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 25),
      children: [
        _StatCard(
          icon: Icons.people_alt_rounded,
          label: 'Total Workers',
          value: totalWorkers,
          iconColor: AppColors.primary,
          bgColor: AppColors.primaryFaint,
        ),
        _StatCard(
          icon: Icons.eco_rounded,
          label: "Today's Harvest",
          value: todayHarvest,
          iconColor: const Color(0xFF00897B),
          bgColor: const Color(0xFFE0F2F1),
        ),
        _StatCard(
          icon: Icons.scale_rounded,
          label: 'Month Total KGs',
          value: monthKg,
          iconColor: const Color(0xFFE65100),
          bgColor: const Color(0xFFFFF3E0),
        ),
        _StatCard(
          icon: Icons.currency_rupee_rounded,
          label: 'Monthly Earnings',
          value: monthEarnings,
          iconColor: const Color(0xFFB7943A),
          bgColor: const Color(0xFFFFF8E1),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 25),
      children: [
        _QuickActionCard(
          icon: Icons.add_chart_rounded,
          label: "Add Today's\nHarvest",
          color: const Color(0xFF00897B),
          onTap: () => context.push(AppRoutes.addTeaEntry),
        ),
        _QuickActionCard(
          icon: Icons.person_add_alt_1_rounded,
          label: 'Add\nSupervisor',
          color: const Color(0xFF1565C0),
          onTap: () => context.push(AppRoutes.addSupervisor),
        ),
        _QuickActionCard(
          icon: Icons.bar_chart_rounded,
          label: 'View\nReports',
          color: const Color(0xFF6A1B9A),
          onTap: onViewReports ?? () {},
        ),
        _QuickActionCard(
          icon: Icons.groups_rounded,
          label: 'Add\nWorkers',
          color: const Color(0xFF00695C),
          onTap: () => context.push(AppRoutes.addWorker),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TeaEstate',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5252),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning 🌿',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Director',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.profile),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showSeeAll;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    this.showSeeAll = false,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (showSeeAll)
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              'See All',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stat card
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick action card
// ---------------------------------------------------------------------------

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today's harvest card
// ---------------------------------------------------------------------------

class _TodayHarvestCard extends StatelessWidget {
  final AsyncValue<List<TeaEntry>>? allEntriesAsync;
  final List<TeaEntry> todayEntries;
  final int totalTodayEntries;
  final String todayStr;
  final VoidCallback? onViewWorkers;

  const _TodayHarvestCard({
    required this.allEntriesAsync,
    required this.todayEntries,
    required this.totalTodayEntries,
    required this.todayStr,
    this.onViewWorkers,
  });

  @override
  Widget build(BuildContext context) {
    if (allEntriesAsync == null) {
      return _card(_emptyState('No estate selected.'));
    }

    return allEntriesAsync!.when(
      loading: () => _card(
        const SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      error: (_, __) => _card(_emptyState('Could not load harvest data.')),
      data: (_) {
        if (todayEntries.isEmpty) {
          return _card(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(
                    Icons.eco_outlined,
                    size: 40,
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No harvest entries today',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fmtEntryDate(todayStr) == todayStr
                        ? todayStr
                        : _fmtEntryDate(todayStr),
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textHint.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final totalKg = todayEntries.fold(0.0, (s, e) => s + e.kg);
        final totalAmount = todayEntries.fold(0.0, (s, e) => s + e.totalAmount);

        return _card(
          Column(
            children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primaryFaint,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Worker',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      'KG',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Amount',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 4),
                itemCount: todayEntries.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.divider,
                ),
                itemBuilder: (_, i) => _HarvestRow(
                  entry: todayEntries[i],
                  isLast: i == todayEntries.length - 1,
                ),
              ),
              // Total row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.primaryFaint,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        totalTodayEntries > 5
                            ? 'Top 5 of $totalTodayEntries entries'
                            : '$totalTodayEntries ${totalTodayEntries == 1 ? 'entry' : 'entries'}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryMid,
                        ),
                      ),
                    ),
                    Text(
                      '${totalKg.toStringAsFixed(1)} kg',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 70,
                      child: Text(
                        _fmtAmount(totalAmount),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryMid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          clipContent: true,
        );
      },
    );
  }

  Widget _emptyState(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(
      child: Text(
        msg,
        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textHint),
      ),
    ),
  );

  Widget _card(Widget child, {bool clipContent = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: clipContent
          ? ClipRRect(borderRadius: BorderRadius.circular(18), child: child)
          : child,
    );
  }
}

// ---------------------------------------------------------------------------
// Harvest row
// ---------------------------------------------------------------------------

class _HarvestRow extends StatelessWidget {
  final TeaEntry entry;
  final bool isLast;

  const _HarvestRow({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, isLast ? 16 : 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.workerName,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rate: Rs ${entry.ratePerKg.toStringAsFixed(0)}/kg',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.kg.toStringAsFixed(1)} kg',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 70,
            child: Text(
              'Rs ${entry.totalAmount.toStringAsFixed(0)}',
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
