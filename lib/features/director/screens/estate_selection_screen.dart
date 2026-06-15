import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/estate.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/api_service.dart';
import '../../auth/widgets/auth_curved_header.dart';

class EstateSelectionScreen extends ConsumerStatefulWidget {
  const EstateSelectionScreen({super.key});

  @override
  ConsumerState<EstateSelectionScreen> createState() =>
      _EstateSelectionScreenState();
}

class _EstateSelectionScreenState extends ConsumerState<EstateSelectionScreen> {
  List<Estate>? _estates;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEstates();
  }

  Future<void> _loadEstates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = ref.read(authTokenProvider)!;
      final estates = await ref.read(apiServiceProvider).listEstates(token);
      if (mounted) setState(() { _estates = estates; _isLoading = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        context.go(AppRoutes.login);
        return;
      }
      setState(() { _error = e.message; _isLoading = false; });
    } catch (e, st) {
      debugPrint('[EstateSelection] ERROR: $e');
      debugPrint('[EstateSelection] STACK: $st');
      if (mounted) {
        setState(() {
          _error = 'Failed to load estates. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectEstate(Estate estate) async {
    await ref.read(estateNotifierProvider.notifier).selectEstate(estate);
    if (!mounted) return;
    final profile = ref.read(userProfileNotifierProvider);
    context.go(
      profile?.isSupervisor == true
          ? AppRoutes.supervisorDashboard
          : AppRoutes.home,
    );
  }

  void _showAddEstateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEstateSheet(
        onCreated: (_) {
          Navigator.pop(context);
          _loadEstates();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileNotifierProvider);
    final subtitle = userProfile != null
        ? 'Welcome, ${userProfile.name}'
        : 'Choose your estate to continue';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AuthCurvedHeader(
            title: 'Select Estate',
            subtitle: subtitle,
            height: 250,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEstateSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Estate',
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
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
                onPressed: _loadEstates,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('Retry',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_estates == null || _estates!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.landscape_rounded,
                  size: 64, color: AppColors.primaryLight),
              const SizedBox(height: 20),
              Text(
                'No estates yet',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the button below to add your first estate.',
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
      onRefresh: _loadEstates,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        itemCount: _estates!.length,
        itemBuilder: (context, i) => _EstateCard(
          estate: _estates![i],
          onTap: () => _selectEstate(_estates![i]),
        ),
      ),
    );
  }
}

class _EstateCard extends StatelessWidget {
  final Estate estate;
  final VoidCallback onTap;

  const _EstateCard({required this.estate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = estate.isActive;
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryFaint
                        : AppColors.border.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.landscape_rounded,
                    color: isActive ? AppColors.primary : AppColors.textHint,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estate.name,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppColors.textHint),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              estate.location,
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusChip(isActive: isActive),
                    const SizedBox(height: 6),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textHint, size: 20),
                  ],
                ),
              ],
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

class _AddEstateSheet extends ConsumerStatefulWidget {
  final void Function(Estate) onCreated;

  const _AddEstateSheet({required this.onCreated});

  @override
  ConsumerState<_AddEstateSheet> createState() => _AddEstateSheetState();
}

class _AddEstateSheetState extends ConsumerState<_AddEstateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final token = ref.read(authTokenProvider)!;
      final estate = await ref.read(apiServiceProvider).createEstate(
            token,
            name: _nameController.text.trim(),
            location: _locationController.text.trim(),
          );
      widget.onCreated(estate);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create estate. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'New Estate',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add a new tea estate to the system',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Estate Name',
                  hintText: 'Green Valley Tea Estate',
                  prefixIcon: Icon(Icons.landscape_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  if (v.trim().length < 2) return 'Minimum 2 characters';
                  if (v.trim().length > 100) return 'Maximum 100 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Kandy',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  if (v.trim().length < 2) return 'Minimum 2 characters';
                  if (v.trim().length > 200) return 'Maximum 200 characters';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Create Estate',
                          style: GoogleFonts.dmSans(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
