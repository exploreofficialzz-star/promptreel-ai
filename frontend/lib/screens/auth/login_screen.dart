import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../config/app_config.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isRegisterMode = false;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(authProvider.notifier);
    bool success;
    if (_isRegisterMode) {
      success = await notifier.register(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        name: _nameCtrl.text.trim(),
      );
    } else {
      success = await notifier.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    }
    if (success && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
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
                  Text(
                    AppConfig.footerCredit,
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppShadows.glow,
          ),
          child: const Icon(Icons.movie_filter_rounded, size: 40, color: Colors.black),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: AppSpacing.md),
        ShaderMask(
          shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
          child: Text(
            AppConfig.appName,
            style: AppTypography.displayMedium.copyWith(color: Colors.white),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
        const SizedBox(height: 6),
        Text(
          AppConfig.tagline,
          style: AppTypography.bodySmall,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),
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

            if (authState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(authState.error!,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (_isRegisterMode) ...[
              _buildField(
                controller: _nameCtrl,
                label: 'Full Name',
                hint: 'Your name',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Name required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            _buildField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v?.contains('@') ?? false) ? null : 'Valid email required',
            ),
            const SizedBox(height: AppSpacing.md),

            _buildField(
              controller: _passwordCtrl,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) => (v?.length ?? 0) < 8 ? 'Min 8 characters' : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            AppButton(
              label: _isRegisterMode ? 'Create Account' : 'Sign In',
              onPressed: _submit,
              fullWidth: true,
              isLoading: authState.isLoading,
            ),
            const SizedBox(height: AppSpacing.md),

            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() => _isRegisterMode = !_isRegisterMode);
                },
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
                        text: _isRegisterMode ? 'Sign In' : 'Create one',
                        style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
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
            style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          style: AppTypography.bodyLarge.copyWith(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
