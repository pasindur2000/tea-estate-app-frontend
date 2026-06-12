import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/worker.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/api_service.dart';
import '../../auth/widgets/tea_primary_button.dart';
import '../../auth/widgets/tea_text_field.dart';

class AddTeaEntryScreen extends ConsumerStatefulWidget {
  const AddTeaEntryScreen({super.key});

  @override
  ConsumerState<AddTeaEntryScreen> createState() => _AddTeaEntryScreenState();
}

class _AddTeaEntryScreenState extends ConsumerState<AddTeaEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFieldKey = GlobalKey<FormFieldState<DateTime?>>();

  final _kgController = TextEditingController();
  final _rateController = TextEditingController(text: '120');

  final _kgFocus = FocusNode();
  final _rateFocus = FocusNode();

  String? _selectedWorkerId;
  String? _selectedWorkerName;
  DateTime _entryDate = DateTime.now();
  bool _isSubmitting = false;
  List<Worker> _workers = [];
  bool _loadingWorkers = true;

  double get _totalAmount {
    final kg = double.tryParse(_kgController.text) ?? 0;
    final rate = double.tryParse(_rateController.text) ?? 0;
    return kg * rate;
  }

  @override
  void initState() {
    super.initState();
    _kgController.addListener(() => setState(() {}));
    _rateController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileNotifierProvider);
      if (profile != null && !profile.isDirector) {
        context.go(AppRoutes.home);
        return;
      }
      _loadWorkers();
    });
  }

  @override
  void dispose() {
    _kgController.dispose();
    _rateController.dispose();
    _kgFocus.dispose();
    _rateFocus.dispose();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    final estate = ref.read(estateNotifierProvider);
    if (estate == null) return;
    setState(() => _loadingWorkers = true);
    try {
      final token = ref.read(authTokenProvider)!;
      final workers =
          await ref.read(apiServiceProvider).listWorkers(token, estate.estateId);
      if (!mounted) return;
      setState(() {
        _workers = workers.where((w) => w.isActive).toList();
        _loadingWorkers = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingWorkers = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2020),
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
      setState(() => _entryDate = picked);
      _dateFieldKey.currentState?.didChange(picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSubmitting = true);
    try {
      final estate = ref.read(estateNotifierProvider)!;
      final token = ref.read(authTokenProvider)!;

      await ref.read(apiServiceProvider).createTeaEntry(
            token,
            estateId: estate.estateId,
            workerId: _selectedWorkerId!,
            workerName: _selectedWorkerName!,
            date: _formatDate(_entryDate),
            kg: double.parse(_kgController.text.trim()),
            ratePerKg: double.parse(_rateController.text.trim()),
          );

      // Invalidate all tea entry caches so home tab refreshes
      ref.invalidate(teaEntriesProvider);

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
                    'Entry recorded for $_selectedWorkerName — '
                    '${_kgController.text.trim()} kg',
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
      _showError('Failed to record entry. Please try again.');
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

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String _fmtDisplay(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
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
              _sectionLabel('Worker & Date'),
              const SizedBox(height: 14),

              // Worker dropdown
              _WorkerDropdownField(
                value: _selectedWorkerId,
                workers: _workers,
                isLoading: _loadingWorkers,
                onChanged: (workerId) {
                  final w =
                      _workers.firstWhere((w) => w.workerId == workerId);
                  setState(() {
                    _selectedWorkerId = workerId;
                    _selectedWorkerName = w.name;
                  });
                },
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Please select a worker' : null,
              ),
              const SizedBox(height: 18),

              // Date picker
              FormField<DateTime?>(
                key: _dateFieldKey,
                initialValue: _entryDate,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) =>
                    v == null ? 'Please select an entry date' : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entry Date',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
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
                            const Icon(Icons.calendar_today_outlined,
                                size: 20, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _fmtDisplay(_entryDate),
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textHint, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _sectionLabel('Harvest Details'),
              const SizedBox(height: 14),

              // KG input
              TeaTextField(
                controller: _kgController,
                focusNode: _kgFocus,
                label: 'Weight (kg)',
                hint: 'e.g. 24.5',
                prefixIcon: Icons.scale_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_rateFocus),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Weight is required';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid weight greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Rate per KG
              TeaTextField(
                controller: _rateController,
                focusNode: _rateFocus,
                label: 'Rate per KG (Rs)',
                hint: 'e.g. 120',
                prefixIcon: Icons.currency_rupee_rounded,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Rate is required';
                  }
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid rate greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Total amount preview
              _TotalAmountPreview(amount: _totalAmount),
              const SizedBox(height: 36),

              TeaPrimaryButton(
                label: 'Record Harvest Entry',
                onPressed: _submit,
                isLoading: _isSubmitting,
                icon: Icons.add_chart_rounded,
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
        'Add Harvest Entry',
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
              'Record the daily tea harvest weight for a worker. '
              'Total amount is calculated automatically.',
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
// Total amount preview
// ---------------------------------------------------------------------------

class _TotalAmountPreview extends StatelessWidget {
  final double amount;

  const _TotalAmountPreview({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: amount > 0
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: amount > 0
              ? AppColors.primary.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                size: 20,
                color: amount > 0 ? AppColors.primary : AppColors.textHint,
              ),
              const SizedBox(width: 12),
              Text(
                'Total Amount',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: amount > 0
                      ? AppColors.textPrimary
                      : AppColors.textHint,
                ),
              ),
            ],
          ),
          Text(
            amount > 0 ? 'Rs ${amount.toStringAsFixed(2)}' : 'Rs 0.00',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: amount > 0 ? AppColors.primary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Worker dropdown
// ---------------------------------------------------------------------------

class _WorkerDropdownField extends StatelessWidget {
  final String? value;
  final List<Worker> workers;
  final bool isLoading;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  const _WorkerDropdownField({
    required this.value,
    required this.workers,
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
          'Worker',
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
                    strokeWidth: 2, color: AppColors.primary),
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
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              hintText: 'Select a worker',
            ),
            items: workers
                .map(
                  (w) => DropdownMenuItem<String>(
                    value: w.workerId,
                    child: Text(w.name),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}
