import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/tea_entry.dart';
import '../../../../core/providers/auth_providers.dart';
import '../../../../core/router/app_router.dart';

String _todayStr() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _fmtKg(double kg) {
  if (kg >= 1000) return '${(kg / 1000).toStringAsFixed(1)}t';
  return '${kg.toStringAsFixed(1)} kg';
}

class SupervisorHomeTab extends ConsumerWidget {
  const SupervisorHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileNotifierProvider);
    if (profile != null) {
      debugPrint('─────────────── Supervisor Profile ───────────────');
      debugPrint('  Name     : ${profile.name}');
      debugPrint('  Email    : ${profile.email}');
      debugPrint('  Role     : ${profile.role}');
      debugPrint('  EstateID : ${profile.estateId ?? "—"}');
      debugPrint('  Status   : ${profile.status}');
      debugPrint('──────────────────────────────────────────────────');
    }

    final estate = ref.watch(estateNotifierProvider);

    final workersAsync = estate != null
        ? ref.watch(workersProvider(estate.estateId))
        : null;

    final allEntriesAsync = estate != null
        ? ref.watch(teaEntriesProvider((estate.estateId, null)))
        : null;

    final today = _todayStr();
    final allEntries = allEntriesAsync?.valueOrNull ?? [];
    final todayKg =
        allEntries.where((e) => e.date == today).fold(0.0, (s, e) => s + e.kg);

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
          const _SupervisorHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 25),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.people_alt_rounded,
                          label: 'Total Workers',
                          value: totalWorkersVal,
                          iconColor: AppColors.primary,
                          bgColor: AppColors.primaryFaint,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.eco_rounded,
                          label: "Today's Harvest",
                          value: entryVal(allEntriesAsync, _fmtKg(todayKg)),
                          iconColor: const Color(0xFF00897B),
                          bgColor: const Color(0xFFE0F2F1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                const _SectionHeader(title: 'Quick Actions'),
                GridView.count(
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
                      icon: Icons.groups_rounded,
                      label: 'Add\nWorkers',
                      color: const Color(0xFF00695C),
                      onTap: () => context.push(AppRoutes.addWorker),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _SupervisorHeader extends ConsumerWidget {
  const _SupervisorHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileNotifierProvider);
    final displayName = profile?.name.split(' ').first ?? 'Supervisor';

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
                      const Icon(Icons.eco_rounded,
                          color: Colors.white, size: 20),
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
                        child: const Icon(Icons.notifications_outlined,
                            color: Colors.white, size: 22),
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
                        displayName,
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
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 28),
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

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
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
          const SizedBox(height: 14),
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
