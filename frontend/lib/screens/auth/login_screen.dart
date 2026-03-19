import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../config/app_config.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isRegisterMode  = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── Email validator ────────────────────────────────────────────────────────
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authProvider.notifier);
    bool success;

    if (_isRegisterMode) {
      success = await notifier.register(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        name:     _nameCtrl.text.trim(),
      );
      if (success && mounted) {
        // Navigate to email verification screen
        _showVerificationScreen(_emailCtrl.text.trim());
        return;
      }
    } else {
      success = await notifier.login(
        email:    _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (success && mounted) context.go('/home');
    }
  }

  void _showVerificationScreen(String email) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _VerifyEmailScreen(email: email),
      ),
    );
  }

  void _showForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const _ForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _buildLogo(),
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildForm(authState),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(AppConfig.footerCredit,
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppShadows.glow,
          ),
          child: const Icon(Icons.movie_filter_rounded,
              size: 40, color: Colors.black),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: AppSpacing.md),
        ShaderMask(
          shaderCallback: (b) =>
              AppColors.primaryGradient.createShader(b),
          child: Text(AppConfig.appName,
              style: AppTypography.displayMedium
                  .copyWith(color: Colors.white)),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
        const SizedBox(height: 6),
        Text(AppConfig.tagline,
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center)
            .animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  Widget _buildForm(AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isRegisterMode ? 'Create Account' : 'Welcome Back',
              style: AppTypography.displaySmall,
            ),
            const SizedBox(height: 4),
            Text(
              _isRegisterMode
                  ? 'Start creating AI video plans for free'
                  : 'Sign in to your PromptReel account',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Error Banner ────────────────────────────────────────────────
            if (authState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                      color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(authState.error!,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Name field (register only) ──────────────────────────────────
            if (_isRegisterMode) ...[
              _buildField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'Your name',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v?.trim().length ?? 0) < 2
                    ? 'Name must be at least 2 characters'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Email field ─────────────────────────────────────────────────
            _buildField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Password field ──────────────────────────────────────────────
            _buildField(
              controller: _passwordCtrl,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) => (v?.length ?? 0) < 8
                  ? 'Password must be at least 8 characters'
                  : null,
            ),

            // ── Forgot Password ─────────────────────────────────────────────
            if (!_isRegisterMode) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showForgotPassword,
                  child: Text(
                    'Forgot password?',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // ── Submit Button ───────────────────────────────────────────────
            AppButton(
              label: _isRegisterMode ? 'Create Account' : 'Sign In',
              onPressed: _submit,
              fullWidth: true,
              isLoading: authState.isLoading,
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Toggle Register/Login ───────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: () => setState(
                    () => _isRegisterMode = !_isRegisterMode),
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.bodySmall,
                    children: [
                      TextSpan(
                        text: _isRegisterMode
                            ? 'Already have an account? '
                            : "Don't have an account? ",
                      ),
                      TextSpan(
                        text: _isRegisterMode
                            ? 'Sign In'
                            : 'Create one',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2);
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          style: AppTypography.bodyLarge.copyWith(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                Icon(icon, size: 18, color: AppColors.textMuted),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

// ─── Verify Email Screen ──────────────────────────────────────────────────────
class _VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  const _VerifyEmailScreen({required this.email});

  @override
  ConsumerState<_VerifyEmailScreen> createState() =>
      _VerifyEmailScreenState();
}

class _VerifyEmailScreenState
    extends ConsumerState<_VerifyEmailScreen> {
  final _codeCtrl  = TextEditingController();
  bool _isLoading  = false;
  bool _isResending= false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_codeCtrl.text.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(apiServiceProvider).verifyEmail(
        email: widget.email,
        code:  _codeCtrl.text.trim(),
      );
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
        context.go('/home');
      }
    } catch (e) {
      setState(() => _error = ApiService.extractError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await ref.read(apiServiceProvider).resendVerification(
          email: widget.email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ New code sent to your email!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = ApiService.extractError(e));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius:
                      BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mark_email_unread_outlined,
                            color: AppColors.primary, size: 32),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text('Check Your Email',
                          style: AppTypography.displaySmall),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'We sent a 6-digit code to\n${widget.email}',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Code input
                    Text('Verification Code',
                        style: AppTypography.labelMedium
                            .copyWith(
                                color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: AppTypography.displaySmall
                          .copyWith(
                              letterSpacing: 12,
                              color: AppColors.primary),
                      decoration: InputDecoration(
                        hintText: '000000',
                        counterText: '',
                        hintStyle: AppTypography.displaySmall
                            .copyWith(
                                color: AppColors.border,
                                letterSpacing: 12),
                      ),
                      onChanged: (v) {
                        if (v.length == 6) _verify();
                      },
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.error)),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    AppButton(
                      label: 'Verify Email',
                      onPressed: _verify,
                      fullWidth: true,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Center(
                      child: GestureDetector(
                        onTap: _isResending ? null : _resend,
                        child: Text(
                          _isResending
                              ? 'Sending...'
                              : 'Didn\'t receive it? Resend code',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go('/home');
                        },
                        child: Text(
                          'Skip for now',
                          style: AppTypography.labelSmall
                              .copyWith(
                                  color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Forgot Password Screen ───────────────────────────────────────────────────
class _ForgotPasswordScreen extends ConsumerStatefulWidget {
  const _ForgotPasswordScreen();

  @override
  ConsumerState<_ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<_ForgotPasswordScreen> {
  final _emailCtrl   = TextEditingController();
  final _codeCtrl    = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading    = false;
  bool _codeSent     = false;
  bool _obscurePass  = true;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your email address');
      return;
    }
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(_emailCtrl.text.trim())) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(apiServiceProvider).forgotPassword(
          email: _emailCtrl.text.trim());
      setState(() { _codeSent = true; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error     = ApiService.extractError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_codeCtrl.text.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    if (_passCtrl.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(apiServiceProvider).resetPassword(
        email:    _emailCtrl.text.trim(),
        code:     _codeCtrl.text.trim(),
        password: _passCtrl.text,
      );
      setState(() {
        _success   = '✅ Password reset! You can now sign in.';
        _isLoading = false;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error     = ApiService.extractError(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius:
                      BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Center(
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_reset_outlined,
                            color: AppColors.error, size: 32),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text('Reset Password',
                          style: AppTypography.displaySmall),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _codeSent
                            ? 'Enter the code sent to your email\nand set a new password'
                            : 'Enter your email and we\'ll\nsend you a reset code',
                        style: AppTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Success message
                    if (_success != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              AppColors.success.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                              color: AppColors.success
                                  .withOpacity(0.3)),
                        ),
                        child: Text(_success!,
                            style: AppTypography.bodySmall
                                .copyWith(
                                    color: AppColors.success)),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Error message
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                              color: AppColors.error
                                  .withOpacity(0.3)),
                        ),
                        child: Text(_error!,
                            style: AppTypography.bodySmall
                                .copyWith(
                                    color: AppColors.error)),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Email field
                    _ForgotField(
                      controller: _emailCtrl,
                      label: 'Email Address',
                      hint: 'you@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !_codeSent,
                    ),

                    if (_codeSent) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ForgotField(
                        controller: _codeCtrl,
                        label: '6-Digit Reset Code',
                        hint: '000000',
                        icon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ForgotField(
                        controller: _passCtrl,
                        label: 'New Password',
                        hint: '••••••••',
                        icon: Icons.lock_outline,
                        obscure: _obscurePass,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePass
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () => setState(
                              () => _obscurePass = !_obscurePass),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ForgotField(
                        controller: _confirmCtrl,
                        label: 'Confirm New Password',
                        hint: '••••••••',
                        icon: Icons.check_circle_outline,
                        obscure: true,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    AppButton(
                      label: _codeSent
                          ? 'Reset Password'
                          : 'Send Reset Code',
                      onPressed:
                          _codeSent ? _resetPassword : _sendCode,
                      fullWidth: true,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForgotField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final bool enabled;
  final int? maxLength;
  final Widget? suffixIcon;

  const _ForgotField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.enabled = true,
    this.maxLength,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          enabled: enabled,
          maxLength: maxLength,
          style: AppTypography.bodyLarge.copyWith(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon:
                Icon(icon, size: 18, color: AppColors.textMuted),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
