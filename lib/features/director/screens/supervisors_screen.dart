import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/api_service.dart';

class SupervisorsScreen extends ConsumerStatefulWidget {
  const SupervisorsScreen({super.key});

  @override
  ConsumerState<SupervisorsScreen> createState() => _SupervisorsScreenState();
}

class _SupervisorsScreenState extends ConsumerState<SupervisorsScreen> {
  List<UserProfile>? _supervisors;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = ref.read(authTokenProvider)!;
      final estateId = ref.read(estateNotifierProvider)!.estateId;
      final supervisors =
          await ref.read(apiServiceProvider).listSupervisors(token, estateId);
      if (mounted) setState(() { _supervisors = supervisors; _isLoading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) { context.go(AppRoutes.login); return; }
      setState(() { _error = e.message; _isLoading = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load supervisors. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _goToAddSupervisor() async {
    await context.push(AppRoutes.addSupervisor);
    // Refresh list when returning from add-supervisor
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final estate = ref.watch(estateNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supervisors',
              style: GoogleFonts.playfairDisplay(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (estate != null)
              Text(
                estate.name,
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToAddSupervisor,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: Text(
          'Add Supervisor',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 52, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('Retry',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_supervisors == null || _supervisors!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 64, color: AppColors.primaryLight),
              const SizedBox(height: 20),
              Text(
                'No supervisors yet',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the button below to add your first supervisor.',
                style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _supervisors!.length,
        itemBuilder: (context, i) => _SupervisorCard(
          supervisor: _supervisors![i],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supervisor card
// ---------------------------------------------------------------------------

class _SupervisorCard extends StatelessWidget {
  final UserProfile supervisor;

  const _SupervisorCard({required this.supervisor});

  @override
  Widget build(BuildContext context) {
    final isActive = supervisor.status == 'active';
    final initials = supervisor.name
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar with initials
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryFaint
                    : AppColors.border.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isActive ? AppColors.primary : AppColors.textHint,
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
                    supervisor.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    supervisor.email,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _StatusChip(isActive: isActive),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;
  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.textHint.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.textHint,
        ),
      ),
    );
  }
}
