import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';

// ---------------------------------------------------------------------------
// Model & mock data
// ---------------------------------------------------------------------------

class _Worker {
  final String id;
  final String name;
  final String nic;
  final String phone;
  final String estateName;
  final DateTime joinedDate;
  final double normalDailyKg;
  final double todayKg;

  const _Worker({
    required this.id,
    required this.name,
    required this.nic,
    required this.phone,
    required this.estateName,
    required this.joinedDate,
    required this.normalDailyKg,
    required this.todayKg,
  });

  double get performanceRatio => todayKg / normalDailyKg;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

final _mockWorkers = [
  _Worker(
    id: 'w1',
    name: 'Kamal Perera',
    nic: '981234567V',
    phone: '0771234567',
    estateName: 'Nuwara Eliya Estate',
    joinedDate: DateTime(2020, 3, 15),
    normalDailyKg: 40.0,
    todayKg: 45.5,
  ),
  _Worker(
    id: 'w2',
    name: 'Nimal Silva',
    nic: '875432109V',
    phone: '0712345678',
    estateName: 'Kandy Valley Estate',
    joinedDate: DateTime(2019, 7, 1),
    normalDailyKg: 38.0,
    todayKg: 38.2,
  ),
  _Worker(
    id: 'w3',
    name: 'Sunil Fernando',
    nic: '921567890V',
    phone: '0761234567',
    estateName: 'Dimbula Estate',
    joinedDate: DateTime(2021, 1, 10),
    normalDailyKg: 42.0,
    todayKg: 35.8,
  ),
  _Worker(
    id: 'w4',
    name: 'Priya Jayawardena',
    nic: '19985678901',
    phone: '0781234567',
    estateName: 'Uva Highland Estate',
    joinedDate: DateTime(2022, 5, 20),
    normalDailyKg: 36.0,
    todayKg: 29.0,
  ),
  _Worker(
    id: 'w5',
    name: 'Kumari Bandara',
    nic: '956789012V',
    phone: '0751234567',
    estateName: 'Nuwara Eliya Estate',
    joinedDate: DateTime(2018, 11, 5),
    normalDailyKg: 44.0,
    todayKg: 44.0,
  ),
  _Worker(
    id: 'w6',
    name: 'Rohan Dissanayake',
    nic: '20001234567',
    phone: '0701234567',
    estateName: 'Kandy Valley Estate',
    joinedDate: DateTime(2023, 2, 14),
    normalDailyKg: 35.0,
    todayKg: 31.5,
  ),
  _Worker(
    id: 'w7',
    name: 'Malini Wickramasinghe',
    nic: '891234500V',
    phone: '0791234567',
    estateName: 'Dimbula Estate',
    joinedDate: DateTime(2017, 6, 30),
    normalDailyKg: 46.0,
    todayKg: 48.2,
  ),
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Color _performanceColor(double ratio) {
  if (ratio >= 1.0) return AppColors.primary;
  if (ratio >= 0.75) return const Color(0xFFE65100);
  return AppColors.error;
}

String _performanceLabel(double ratio) {
  if (ratio >= 1.0) return 'Exceeding';
  if (ratio >= 0.75) return 'Near Target';
  return 'Below Target';
}

String _fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

// ---------------------------------------------------------------------------
// WorkersTab
// ---------------------------------------------------------------------------

class WorkersTab extends StatefulWidget {
  const WorkersTab({super.key});

  @override
  State<WorkersTab> createState() => _WorkersTabState();
}

class _WorkersTabState extends State<WorkersTab> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _openPerformance(_Worker worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkerPerformanceSheet(worker: worker),
    );
  }

  String get _dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sel = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    if (sel == today) return 'Today';
    if (sel == yesterday) return 'Yesterday';
    return _fmtDate(_selectedDate);
  }

  double get _totalKg =>
      _mockWorkers.fold(0.0, (sum, w) => sum + w.todayKg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildDateFilterRow(),
          const SizedBox(height: 12),
          _buildSummaryBanner(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: _mockWorkers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _WorkerCard(
                worker: _mockWorkers[i],
                onTap: () => _openPerformance(_mockWorkers[i]),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addWorker),
        backgroundColor: AppColors.primary,
        elevation: 3,
        icon: const Icon(Icons.person_add_alt_1_rounded,
            color: Colors.white, size: 20),
        label: Text(
          'Add Worker',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
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
        'All Workers',
        style: GoogleFonts.playfairDisplay(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  Widget _buildDateFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Text(
            'Showing data for',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryFaint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 13, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    _dateLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _SummaryPill(
              icon: Icons.people_alt_rounded,
              label: 'Workers',
              value: '${_mockWorkers.length}',
            ),
            Container(
              width: 1,
              height: 34,
              color: Colors.white.withValues(alpha: 0.2),
              margin: const EdgeInsets.symmetric(horizontal: 18),
            ),
            _SummaryPill(
              icon: Icons.eco_rounded,
              label: 'Total Harvest',
              value: '${_totalKg.toStringAsFixed(1)} kg',
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _dateLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary pill
// ---------------------------------------------------------------------------

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.75), size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Worker card
// ---------------------------------------------------------------------------

class _WorkerCard extends StatelessWidget {
  final _Worker worker;
  final VoidCallback onTap;

  const _WorkerCard({required this.worker, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ratio = worker.performanceRatio;
    final color = _performanceColor(ratio);
    final pct = (ratio * 100).round();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      worker.initials,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + estate + progress bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        worker.estateName,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0.0, 1.0),
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Kg + percentage badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${worker.todayKg} kg',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'of ${worker.normalDailyKg.toStringAsFixed(0)} kg',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$pct%',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Performance bottom sheet
// ---------------------------------------------------------------------------

class _WorkerPerformanceSheet extends StatelessWidget {
  final _Worker worker;

  const _WorkerPerformanceSheet({required this.worker});

  @override
  Widget build(BuildContext context) {
    final ratio = worker.performanceRatio;
    final color = _performanceColor(ratio);
    final pct = (ratio * 100).round();
    final label = _performanceLabel(ratio);
    final diff = worker.todayKg - worker.normalDailyKg;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Worker header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      worker.initials,
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        worker.estateName,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // NIC + Phone chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _InfoChip(icon: Icons.badge_outlined, label: worker.nic),
                const SizedBox(width: 8),
                _InfoChip(icon: Icons.phone_outlined, label: worker.phone),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Arc gauge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: ratio.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) {
                return SizedBox(
                  height: 130,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 130),
                        painter: _GaugePainter(
                          progress: value,
                          progressColor: color,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$pct%',
                              style: GoogleFonts.dmSans(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: color,
                                letterSpacing: -1.5,
                              ),
                            ),
                            Text(
                              'of daily target',
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.eco_rounded,
                    label: "Today's Harvest",
                    value: '${worker.todayKg} kg',
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBox(
                    icon: Icons.flag_outlined,
                    label: 'Daily Target',
                    value: '${worker.normalDailyKg.toStringAsFixed(0)} kg',
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBox(
                    icon: diff >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    label: diff >= 0 ? 'Over Target' : 'Under Target',
                    value:
                        '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg',
                    color: diff >= 0 ? AppColors.primary : AppColors.error,
                  ),
                ),
              ],
            ),
          ),

          // Joined date footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 6),
                Text(
                  'Joined ${_fmtDate(worker.joinedDate)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info chip
// ---------------------------------------------------------------------------

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat box (inside bottom sheet)
// ---------------------------------------------------------------------------

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
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
// Semicircular gauge painter
// ---------------------------------------------------------------------------

class _GaugePainter extends CustomPainter {
  final double progress; // 0.0 – 1.0
  final Color progressColor;

  const _GaugePainter({
    required this.progress,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 18.0;
    final center = Offset(size.width / 2, size.height);
    final radius = (size.width / 2) - strokeWidth;

    // Track arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0.01) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi * progress,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.progressColor != progressColor;
}
