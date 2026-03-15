import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/generate_provider.dart';
import '../../providers/projects_provider.dart';
import '../../services/ad_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/section_selector.dart';
import '../../widgets/ads/banner_ad_widget.dart';
import '../../config/app_config.dart';

class CreateScreen extends ConsumerStatefulWidget {
  final String? initialIdea;
  const CreateScreen({super.key, this.initialIdea});

  @override
  ConsumerState<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends ConsumerState<CreateScreen> {
  final _ideaCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  int _currentStep = 0;
  static const int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    if (widget.initialIdea != null) {
      _ideaCtrl.text = widget.initialIdea!;
      ref.read(generateFormProvider.notifier).setIdea(widget.initialIdea!);
    }
    // Pre-load interstitial so it's ready after generation
    AdService.instance.loadInterstitial();
  }

  @override
  void dispose() {
    _ideaCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final form = ref.read(generateFormProvider);
    if (!form.isValid) {
      _showError('Please enter a video idea (at least 10 characters)');
      return;
    }

    final success = await ref.read(generationProvider.notifier).generate(form);
    if (success && mounted) {
      final project = ref.read(generationProvider).project;
      if (project != null) {
        ref.read(projectsProvider.notifier).addProject(project);
        ref.read(authProvider.notifier).refreshUser();
        // Show interstitial ad for free users between generate and results
        final user = ref.read(currentUserProvider);
        await AdService.instance.showInterstitial(user);
        if (mounted) context.go('/results/${project.id}', extra: project);
      }
    } else if (mounted) {
      final error = ref.read(generationProvider).error;
      _showError(error ?? 'Generation failed. Please try again.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(generateFormProvider);
    final genState = ref.watch(generationProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: StickyBannerAd(
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(formState),
                _buildStepIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_currentStep),
                        child: _buildStep(formState, user),
                      ),
                    ),
                  ),
                ),
                _buildBottomBar(formState, genState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(formState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: _currentStep > 0 ? _prevStep : () => context.go('/home'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Video Plan', style: AppTypography.headlineMedium),
                Text(
                  'Step ${_currentStep + 1} of $_totalSteps',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  gradient: isDone || isActive ? AppColors.primaryGradient : null,
                  color: isDone || isActive ? null : AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep(formState, user) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(formState, user);
      case 1:
        return _buildStep2(formState, user);
      case 2:
        return _buildStep3(formState, user);
      default:
        return const SizedBox();
    }
  }

  // ── Step 1: Idea + Content Type + Platform ──────────────────────────────
  Widget _buildStep1(formState, user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('🎬', 'Your Video Idea', 'What is your video about?'),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _ideaCtrl,
          maxLines: 4,
          maxLength: 1000,
          onChanged: ref.read(generateFormProvider.notifier).setIdea,
          style: AppTypography.bodyLarge.copyWith(fontSize: 15),
          decoration: InputDecoration(
            hintText: 'e.g. "Top 10 deadliest snakes in the world and how to survive them"',
            hintMaxLines: 3,
            counterStyle: AppTypography.labelSmall,
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionSelector<String>(
          label: 'Content Type',
          selected: formState.contentType,
          onSelect: ref.read(generateFormProvider.notifier).setContentType,
          options: AppConfig.contentTypes.map((t) => SectionOption<String>(
            value: t['name'],
            label: t['name'],
            emoji: t['icon'],
            description: t['desc'],
          )).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionSelector<String>(
          label: 'Target Platform',
          selected: formState.platform,
          onSelect: ref.read(generateFormProvider.notifier).setPlatform,
          options: AppConfig.platforms.map((p) => SectionOption<String>(
            value: p['name'],
            label: p['name'],
            emoji: p['icon'],
          )).toList(),
        ),
      ],
    ).animate().fadeIn();
  }

  // ── Step 2: Duration + Generator ─────────────────────────────────────────
  Widget _buildStep2(formState, user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('⏱️', 'Video Duration', 'How long should your video be?'),
        const SizedBox(height: AppSpacing.sm),
        SectionSelector<int>(
          label: '',
          selected: formState.durationMinutes,
          onSelect: ref.read(generateFormProvider.notifier).setDuration,
          options: AppConfig.durations.map((d) {
            final isPaid = d['paid'] == true;
            final isLocked = isPaid && (user?.isFree ?? true);
            return SectionOption<int>(
              value: d['minutes'] as int,
              label: d['label'] as String,
              description: d['desc'] as String,
              locked: isLocked,
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _sectionTitle('🤖', 'AI Video Generator', 'Which AI will you use to create the video?'),
        const SizedBox(height: AppSpacing.sm),
        ...AppConfig.generators.asMap().entries.map((e) {
          final gen = e.value;
          final isSelected = formState.generator == gen['name'];
          final clipDuration = gen['clip'] as int;
          final durationSec = _getDurationSeconds(formState.durationMinutes);
          final totalScenes = durationSec ~/ clipDuration;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => ref.read(generateFormProvider.notifier).setGenerator(gen['name']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.cardGradient : null,
                  color: isSelected ? null : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? AppColors.primary.withOpacity(0.6) : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected ? AppShadows.primary : null,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 5 : 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(gen['name'] as String, style: AppTypography.titleMedium),
                          Text(gen['desc'] as String, style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '$totalScenes scenes',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate(delay: Duration(milliseconds: e.key * 50)).fadeIn().slideX(begin: -0.05),
          );
        }),
      ],
    ).animate().fadeIn();
  }

  // ── Step 3: Toggles + Review ──────────────────────────────────────────────
  Widget _buildStep3(formState, user) {
    final clipDuration = _getClipDuration(formState.generator);
    final totalScenes = _getDurationSeconds(formState.durationMinutes) ~/ clipDuration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('⚙️', 'Extra Options', 'Enhance your video plan'),
        const SizedBox(height: AppSpacing.sm),
        ToggleRow(
          label: 'Generate Image Prompts',
          subtitle: 'Midjourney, Leonardo AI, Stable Diffusion, DALL-E prompts for each scene',
          value: formState.generateImagePrompts,
          onChanged: ref.read(generateFormProvider.notifier).setGenerateImagePrompts,
          badge: 'OPTIONAL',
        ),
        const SizedBox(height: 8),
        ToggleRow(
          label: 'Generate Voice-Over Script',
          subtitle: 'Timed narration script with [00:00] markers (text only, no audio)',
          value: formState.generateVoiceOver,
          onChanged: ref.read(generateFormProvider.notifier).setGenerateVoiceOver,
          badge: 'OPTIONAL',
        ),
        const SizedBox(height: AppSpacing.lg),

        // Review summary
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.checklist_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Plan Summary', style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
                ],
              ),
              const Divider(height: 16),
              _reviewRow('Idea', formState.idea.length > 60 ? '${formState.idea.substring(0, 60)}...' : formState.idea),
              _reviewRow('Type', formState.contentType),
              _reviewRow('Platform', formState.platform),
              _reviewRow('Duration', '${formState.durationMinutes} minutes'),
              _reviewRow('Generator', formState.generator),
              _reviewRow('Total Scenes', '$totalScenes clips × ${clipDuration}s'),
              _reviewRow('Image Prompts', formState.generateImagePrompts ? '✅ Yes' : '❌ No'),
              _reviewRow('Voice-Over', formState.generateVoiceOver ? '✅ Yes' : '❌ No'),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.98, 0.98)),

        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI generation usually takes 15-30 seconds. Please keep the app open.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTypography.bodySmall),
          ),
          Expanded(
            child: Text(value, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String emoji, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.headlineMedium),
          ],
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTypography.bodySmall),
      ],
    );
  }

  Widget _buildBottomBar(formState, genState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: _currentStep < _totalSteps - 1
            ? AppButton(
                label: 'Continue →',
                onPressed: formState.isValid || _currentStep > 0 ? _nextStep : null,
                fullWidth: true,
                height: 52,
              )
            : AppButton(
                label: genState.isGenerating ? 'Generating your plan...' : '✦  Generate Video Plan',
                onPressed: genState.isGenerating ? null : _generate,
                fullWidth: true,
                height: 52,
                isLoading: genState.isGenerating,
              ),
      ),
    );
  }

  int _getDurationSeconds(int minutes) {
    const map = {1: 60, 3: 180, 5: 300, 10: 600, 20: 1200};
    return map[minutes] ?? 300;
  }

  int _getClipDuration(String generator) {
    const map = {'Runway': 5, 'Pika': 3, 'Kling': 10, 'Sora': 15, 'Luma': 5, 'Haiper': 4, 'Other': 5};
    return map[generator] ?? 5;
  }
}
