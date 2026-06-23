import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/estate_section.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/api_service.dart';

class ManageSectionsScreen extends ConsumerStatefulWidget {
  const ManageSectionsScreen({super.key});

  @override
  ConsumerState<ManageSectionsScreen> createState() =>
      _ManageSectionsScreenState();
}

class _ManageSectionsScreenState extends ConsumerState<ManageSectionsScreen> {
  List<EstateSection>? _sections;
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
      final sections =
          await ref.read(apiServiceProvider).listSections(token, estateId);
      if (mounted) {
        setState(() {
          _sections = sections;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        context.go(AppRoutes.login);
        return;
      }
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load sections. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showSectionSheet({EstateSection? section}) async {
    final nameController = TextEditingController(text: section?.name ?? '');
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SectionSheet(
        formKey: formKey,
        nameController: nameController,
        isEditing: section != null,
        onSave: (name) async {
          final token = ref.read(authTokenProvider)!;
          final estateId = ref.read(estateNotifierProvider)!.estateId;
          final api = ref.read(apiServiceProvider);
          if (section == null) {
            await api.createSection(token, estateId: estateId, name: name);
          } else {
            await api.updateSection(
              token,
              estateId: estateId,
              sectionId: section.sectionId,
              name: name,
            );
          }
        },
      ),
    );

    _load();
  }

  Future<void> _confirmDelete(EstateSection section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Section',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${section.name}"? This cannot be undone.',
          style: GoogleFonts.dmSans(
              fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.dmSans(
                  color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final token = ref.read(authTokenProvider)!;
      final estateId = ref.read(estateNotifierProvider)!.estateId;
      await ref.read(apiServiceProvider).deleteSection(
            token,
            estateId: estateId,
            sectionId: section.sectionId,
          );
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete section. Try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
              'Estate Sections',
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
          child:
              Container(height: 1, color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSectionSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Section',
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
          child: CircularProgressIndicator(color: AppColors.primary));
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

    if (_sections == null || _sections!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.grid_view_rounded,
                  size: 64, color: AppColors.primaryLight),
              const SizedBox(height: 20),
              Text(
                'No sections yet',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Divide your estate into named sections to better manage workers and harvest tracking.',
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
        itemCount: _sections!.length,
        itemBuilder: (context, i) => _SectionCard(
          section: _sections![i],
          index: i,
          onEdit: () => _showSectionSheet(section: _sections![i]),
          onDelete: () => _confirmDelete(_sections![i]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet for add / edit
// ---------------------------------------------------------------------------

class _SectionSheet extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final bool isEditing;
  final Future<void> Function(String name) onSave;

  const _SectionSheet({
    required this.formKey,
    required this.nameController,
    required this.isEditing,
    required this.onSave,
  });

  @override
  State<_SectionSheet> createState() => _SectionSheetState();
}

class _SectionSheetState extends State<_SectionSheet> {
  bool _isSaving = false;

  Future<void> _submit() async {
    if (!widget.formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(widget.nameController.text.trim());
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message), backgroundColor: AppColors.error),
        );
        setState(() => _isSaving = false);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Try again.'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isSaving = false);
      }
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
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Form(
          key: widget.formKey,
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
                widget.isEditing ? 'Edit Section' : 'Add Section',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter a name for this section (e.g. Section A, North Block, Field 1)',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: widget.nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.dmSans(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Section Name',
                  hintText: 'e.g. Section A, North Block',
                  prefixIcon: Icon(Icons.grid_view_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a section name'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          widget.isEditing ? 'Save Changes' : 'Add Section',
                          style: GoogleFonts.dmSans(
                              fontSize: 16, fontWeight: FontWeight.w700),
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

// ---------------------------------------------------------------------------
// Section card
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final EstateSection section;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SectionCard({
    required this.section,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryFaint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                section.name,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 20, color: AppColors.primary),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.error.withValues(alpha: 0.8),
              ),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}
