import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_providers.dart';
import '../../../core/router/app_router.dart';
import '../services/auth_service.dart';
import '../widgets/auth_curved_header.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/tea_primary_button.dart';
import '../widgets/tea_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isSigningIn = false;
  bool _isGoogleSigningIn = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSigningIn = true);
    try {
      await ref.read(authNotifierProvider.notifier).signInWithEmailPassword(
            _emailController.text,
            _passwordController.text,
          );
      if (mounted) context.go(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      _showError(authErrorMessage(e.code));
    } catch (_) {
      _showError('An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() => _isGoogleSigningIn = true);
    try {
      final success =
          await ref.read(authNotifierProvider.notifier).signInWithGoogle();
      if (success && mounted) context.go(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      _showError(authErrorMessage(e.code));
    } catch (_) {
      _showError('Google Sign In failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isGoogleSigningIn = false);
    }
  }

  // debugPrint wraps at ~1020 chars — Firebase ID tokens are longer than that,
  // so we chunk the console output and copy the full token to clipboard instead.
  // Future<void> _logAndCopyToken({
  //   required String method,
  //   required String? firebaseIdToken,
  //   String? googleAccessToken,
  // }) async {
  //   debugPrint('══════════════════════════════════════════');
  //   debugPrint('[Auth] $method sign-in successful');

  //   if (firebaseIdToken != null) {
  //     debugPrint('[Auth] Firebase ID Token — ${firebaseIdToken.length} chars '
  //         '(full token copied to clipboard):');
  //     // Print in 900-char chunks so the console shows it without silent cuts
  //     const chunkSize = 900;
  //     for (int i = 0; i < firebaseIdToken.length; i += chunkSize) {
  //       final end = (i + chunkSize).clamp(0, firebaseIdToken.length);
  //       debugPrint(firebaseIdToken.substring(i, end));
  //     }
  //     await Clipboard.setData(ClipboardData(text: firebaseIdToken));
  //     debugPrint('[Auth] ✓ Firebase ID Token copied to clipboard — paste directly into Swagger');
  //   }

  //   if (googleAccessToken != null) {
  //     debugPrint('[Auth] Google Access Token: $googleAccessToken');
  //   }

  //   debugPrint('══════════════════════════════════════════');
  // }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
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
      body: Column(
        children: [
          AuthCurvedHeader(
            title: 'Welcome Back',
            subtitle: 'Sign in to your account',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    TeaTextField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      label: 'Email Address',
                      hint: 'you@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_passwordFocus),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 20),
                    TeaTextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      label: 'Password',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _signInWithEmailPassword(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please enter your password'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    TeaPrimaryButton(
                      label: 'Sign In',
                      onPressed: _signInWithEmailPassword,
                      isLoading: _isSigningIn,
                    ),
                    const SizedBox(height: 24),
                    _Divider(),
                    const SizedBox(height: 24),
                    GoogleSignInButton(
                      onPressed: _signInWithGoogle,
                      isLoading: _isGoogleSigningIn,
                    ),
                    const SizedBox(height: 32),
                    _buildSignUpLink(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Please enter a valid email';
    return null;
  }

  Widget _buildSignUpLink(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          GestureDetector(
            onTap: () => context.push(AppRoutes.signup),
            child: Text(
              'Sign Up',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textHint),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
