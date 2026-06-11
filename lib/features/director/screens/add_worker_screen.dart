import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/widgets/tea_primary_button.dart';
import '../../auth/widgets/tea_text_field.dart';

// ---------------------------------------------------------------------------
// Estate model — replace with API call when backend is ready
// ---------------------------------------------------------------------------

class _Estate {
  final String id;
  final String name;
  const _Estate({required this.id, required this.name});
}

const _estates = [
  _Estate(id: 'estate_001', name: 'Nuwara Eliya Estate'),
  _Estate(id: 'estate_002', name: 'Kandy Valley Estate'),
  _Estate(id: 'estate_003', name: 'Dimbula Estate'),
  _Estate(id: 'estate_004', name: 'Uva Highland Estate'),
];

// ---------------------------------------------------------------------------

class AddWorkerScreen extends StatefulWidget {
  const AddWorkerScreen({super.key});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _joinedDateFieldKey = GlobalKey<FormFieldState<DateTime?>>();

  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();

  final _nameFocus = FocusNode();
  final _nicFocus = FocusNode();
  final _phoneFocus = FocusNode();

  String? _selectedEstateId;
  DateTime? _joinedDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _nicFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _pickJoinedDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
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
    if (picked != null) {
      setState(() => _joinedDate = picked);
      _joinedDateFieldKey.currentState?.didChange(picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);
    try {
      // TODO: replace stub with real API call
      // POST /api/workers  { name, nic, phone, joinedDate, estateId, status: 'active' }
      await Future.delayed(const Duration(milliseconds: 1200));

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
                    'Worker "${_nameController.text.trim()}" added successfully.',
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
    } catch (_) {
      _showError('Failed to add worker. Please try again.');
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
              _InfoCard(),
              const SizedBox(height: 24),
              _sectionLabel('Personal Details'),
              const SizedBox(height: 14),
              TeaTextField(
                controller: _nameController,
                focusNode: _nameFocus,
                label: 'Full Name',
                hint: 'e.g. Kamal Perera',
                prefixIcon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_nicFocus),
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
                controller: _nicController,
                focusNode: _nicFocus,
                label: 'NIC Number',
                hint: 'e.g. 981234567V or 19981234567',
                prefixIcon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_phoneFocus),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'NIC is required';
                  if (v.trim().length < 9) {
                    return 'NIC must be at least 9 characters';
                  }
                  if (v.trim().length > 12) {
                    return 'NIC must be under 12 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TeaTextField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                label: 'Phone Number',
                hint: 'e.g. 0771234567',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Phone number is required';
                  }
                  if (v.trim().length < 10) {
                    return 'Phone must be at least 10 characters';
                  }
                  if (v.trim().length > 15) {
                    return 'Phone must be under 15 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              _sectionLabel('Assignment'),
              const SizedBox(height: 14),

              // Joined date — FormField so it participates in form validation
              FormField<DateTime?>(
                key: _joinedDateFieldKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) =>
                    v == null ? 'Please select a joined date' : null,
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Joined Date',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickJoinedDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: field.hasError
                                  ? AppColors.error
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 20,
                                color: _joinedDate != null
                                    ? AppColors.primary
                                    : AppColors.textHint,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _joinedDate != null
                                      ? _fmtDate(_joinedDate!)
                                      : 'Select joined date',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: _joinedDate != null
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                    color: _joinedDate != null
                                        ? AppColors.textPrimary
                                        : AppColors.textHint,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textHint,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (field.hasError)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 6, left: 14),
                          child: Text(
                            field.errorText!,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),

              // Estate dropdown
              _EstateDropdownField(
                value: _selectedEstateId,
                onChanged: (v) => setState(() => _selectedEstateId = v),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please select an estate' : null,
              ),
              const SizedBox(height: 36),
              TeaPrimaryButton(
                label: 'Add Worker',
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
        'Add Worker',
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

  static String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ---------------------------------------------------------------------------
// Info card
// ---------------------------------------------------------------------------

class _InfoCard extends StatelessWidget {
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
              'New workers are registered as active and linked to their assigned estate.',
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
// Estate dropdown — styled to match TeaTextField
// ---------------------------------------------------------------------------

class _EstateDropdownField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  const _EstateDropdownField({
    required this.value,
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
          items: _estates
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e.id,
                  child: Text(e.name),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
