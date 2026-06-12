import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/estate.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/api_service.dart';
import '../../auth/widgets/tea_primary_button.dart';
import '../../auth/widgets/tea_text_field.dart';

class AddSupervisorScreen extends ConsumerStatefulWidget {
  const AddSupervisorScreen({super.key});

  @override
  ConsumerState<AddSupervisorScreen> createState() =>
      _AddSupervisorScreenState();
}

class _AddSupervisorScreenState extends ConsumerState<AddSupervisorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _selectedEstateId;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  List<Estate> _estates = [];
  bool _loadingEstates = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Director-only guard — redirect non-directors immediately
      final profile = ref.read(userProfileNotifierProvider);
      if (profile != null && !profile.isDirector) {
        context.go(AppRoutes.home);
        return;
      }
      // Pre-select the estate the director is currently working in
      final selected = ref.read(estateNotifierProvider);
      if (selected != null) {
        setState(() => _selectedEstateId = selected.estateId);
      }
      _loadEstates();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadEstates() async {
    setState(() => _loadingEstates = true);
    try {
      final token = ref.read(authTokenProvider)!;
      final estates = await ref.read(apiServiceProvider).listEstates(token);
      if (!mounted) return;
      setState(() {
        _estates = estates;
        _loadingEstates = false;
        // Keep pre-selected estate only if it's still in the list
        if (_selectedEstateId != null &&
            !_estates.any((e) => e.estateId == _selectedEstateId)) {
          _selectedEstateId = null;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingEstates = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);
    try {
      final token = ref.read(authTokenProvider)!;
      await ref.read(apiServiceProvider).createSupervisor(
            token,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            estateId: _selectedEstateId!,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Supervisor "${_nameController.text.trim()}" created successfully.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Failed to create supervisor. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _InfoCard(),
              const SizedBox(height: 24),
              _sectionLabel('Account Details'),
              const SizedBox(height: 14),
              TeaTextField(
                controller: _nameController,
                focusNode: _nameFocus,
                label: 'Full Name',
                hint: 'e.g. Kamal Perera',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_emailFocus),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  if (v.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  if (v.trim().length > 100) {
                    return 'Name must be under 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TeaTextField(
                controller: _emailController,
                focusNode: _emailFocus,
                label: 'Email Address',
                hint: 'supervisor@example.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TeaTextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                label: 'Password',
                hint: 'Minimum 6 characters',
                prefixIcon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              _sectionLabel('Assignment'),
              const SizedBox(height: 14),
              _EstateDropdownField(
                value: _selectedEstateId,
                estates: _estates,
                isLoading: _loadingEstates,
                onChanged: (v) => setState(() => _selectedEstateId = v),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please select an estate' : null,
              ),
              const SizedBox(height: 36),
              TeaPrimaryButton(
                label: 'Create Supervisor',
                onPressed: _submit,
                isLoading: _isSubmitting,
                icon: Icons.person_add_alt_1_rounded,
              ),
            ],
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Add Supervisor',
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

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.playfairDisplay(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info card
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'The supervisor will use this email and password to log in. '
              'Their account will be linked to the selected estate.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.primaryMid,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estate dropdown — loads real estates from the API
// ---------------------------------------------------------------------------

class _EstateDropdownField extends StatelessWidget {
  final String? value;
  final List<Estate> estates;
  final bool isLoading;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  const _EstateDropdownField({
    required this.value,
    required this.estates,
    required this.isLoading,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estate',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: value,
            onChanged: onChanged,
            validator: validator,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.textHint),
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(14),
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.villa_rounded, size: 20),
              hintText: 'Select an estate',
            ),
            items: estates
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.estateId,
                    child: Text(e.name),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
