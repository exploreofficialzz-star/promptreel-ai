import 'package:flutter/foundation.dart' show kIsWeb;
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
  final _ideaCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  int _currentStep  = 0;
  static const int _totalSteps = 3;

  // ── Content Type Options ──────────────────────────────────────────────────
  static const Map<String, List<Map<String, dynamic>>> _contentTypeOptions = {
    'Educational': [
      {
        'key': 'target_audience', 'label': 'Target Audience', 'icon': '👥',
        'options': ['Kids (5-12)', 'Teens (13-17)', 'Adults (18+)', 'Professionals'],
        'default': 'Adults (18+)',
      },
      {
        'key': 'teaching_style', 'label': 'Teaching Style', 'icon': '📖',
        'options': ['Lecture style', 'Step-by-step tutorial', 'Storytelling', 'Q&A format'],
        'default': 'Step-by-step tutorial',
      },
      {
        'key': 'complexity', 'label': 'Complexity Level', 'icon': '🎯',
        'options': ['Beginner friendly', 'Intermediate', 'Advanced', 'Expert level'],
        'default': 'Beginner friendly',
      },
    ],
    'Narration': [
      {
        'key': 'narrator_voice', 'label': 'Narrator Voice', 'icon': '🎙️',
        'options': ['Male voice', 'Female voice', 'Child voice', 'Elderly voice'],
        'default': 'Male voice',
      },
      {
        'key': 'narrator_accent', 'label': 'Narrator Accent', 'icon': '🌍',
        'options': ['American English', 'British English', 'Australian', 'African', 'Neutral international'],
        'default': 'Neutral international',
      },
      {
        'key': 'narration_pace', 'label': 'Narration Pace', 'icon': '⏱️',
        'options': ['Slow & deliberate', 'Normal pace', 'Fast-paced', 'Dynamic (varies)'],
        'default': 'Normal pace',
      },
      {
        'key': 'story_pov', 'label': 'Story POV', 'icon': '👁️',
        'options': ['First person (I/me)', 'Second person (you)', 'Third person (he/she/they)', 'Omniscient narrator'],
        'default': 'Third person (he/she/they)',
      },
    ],
    'Commentary': [
      {
        'key': 'opinion_strength', 'label': 'Opinion Strength', 'icon': '💬',
        'options': ['Mild & balanced', 'Moderate opinions', 'Strong opinions', 'Very provocative'],
        'default': 'Moderate opinions',
      },
      {
        'key': 'commentary_style', 'label': 'Commentary Style', 'icon': '🎤',
        'options': ['Deep analysis', 'Reaction style', 'Review format', 'Debate style', 'Explainer'],
        'default': 'Deep analysis',
      },
      {
        'key': 'presenter_energy', 'label': 'Presenter Energy', 'icon': '⚡',
        'options': ['Calm & measured', 'Enthusiastic', 'Intense & passionate', 'Sarcastic & witty'],
        'default': 'Enthusiastic',
      },
    ],
    'Documentary': [
      {
        'key': 'documentary_style', 'label': 'Documentary Style', 'icon': '🎬',
        'options': ['Nature & wildlife', 'True crime', 'Historical', 'Science & tech', 'Social issues', 'Biography'],
        'default': 'Historical',
      },
      {
        'key': 'narration_tone', 'label': 'Narration Tone', 'icon': '🎭',
        'options': ['Serious & factual', 'Suspenseful', 'Inspiring & hopeful', 'Neutral & journalistic'],
        'default': 'Serious & factual',
      },
      {
        'key': 'evidence_style', 'label': 'Evidence Style', 'icon': '📊',
        'options': ['Interview-based', 'Data & statistics', 'Field footage style', 'Archive materials', 'Mixed approach'],
        'default': 'Mixed approach',
      },
    ],
    'Storytelling': [
      {
        'key': 'story_genre', 'label': 'Story Genre', 'icon': '📚',
        'options': ['Adventure', 'Romance', 'Mystery & thriller', 'Fantasy', 'Sci-fi', 'Drama', 'Folklore & legend'],
        'default': 'Adventure',
      },
      {
        'key': 'main_character', 'label': 'Main Character Type', 'icon': '🦸',
        'options': ['Classic hero', 'Anti-hero', 'Unlikely hero', 'Ensemble cast', 'No main character'],
        'default': 'Classic hero',
      },
      {
        'key': 'story_arc', 'label': 'Story Arc', 'icon': '📈',
        'options': ['Hero\'s journey', 'Redemption arc', 'Revenge story', 'Discovery & growth', 'Survival story'],
        'default': 'Hero\'s journey',
      },
    ],
    'Comedy': [
      {
        'key': 'humor_style', 'label': 'Humor Style', 'icon': '😂',
        'options': ['Dry & sarcastic', 'Slapstick & physical', 'Dark humor', 'Observational', 'Absurd & surreal', 'Puns & wordplay'],
        'default': 'Observational',
      },
      {
        'key': 'comedy_pacing', 'label': 'Comedy Pacing', 'icon': '⏩',
        'options': ['Rapid-fire jokes', 'Slow burn comedy', 'Build-up & payoff', 'Dynamic mixed pace'],
        'default': 'Build-up & payoff',
      },
      {
        'key': 'comedy_format', 'label': 'Comedy Format', 'icon': '🎪',
        'options': ['Stand-up style', 'Sketch comedy', 'Roast style', 'Parody & satire', 'Storytelling with jokes'],
        'default': 'Storytelling with jokes',
      },
    ],
    'Horror': [
      {
        'key': 'scare_type', 'label': 'Scare Type', 'icon': '👻',
        'options': ['Psychological horror', 'Jump scare based', 'Slow dread buildup', 'Gore & graphic', 'Supernatural', 'Thriller & suspense'],
        'default': 'Psychological horror',
      },
      {
        'key': 'horror_subgenre', 'label': 'Horror Subgenre', 'icon': '🕯️',
        'options': ['Ghost story', 'Slasher', 'Cosmic horror', 'Survival horror', 'Paranormal', 'Creature feature'],
        'default': 'Ghost story',
      },
      {
        'key': 'atmosphere', 'label': 'Atmosphere', 'icon': '🌑',
        'options': ['Dark & oppressive', 'Silent & tense', 'Chaotic & frantic', 'Surreal & dreamlike', 'Isolated & lonely'],
        'default': 'Dark & oppressive',
      },
    ],
    'Motivational': [
      {
        'key': 'energy_level', 'label': 'Energy Level', 'icon': '🔥',
        'options': ['Calm & inspiring', 'High energy', 'Intense & urgent', 'Gentle & nurturing', 'Raw & real'],
        'default': 'High energy',
      },
      {
        'key': 'target_audience', 'label': 'Target Audience', 'icon': '🎯',
        'options': ['Entrepreneurs', 'Athletes & fitness', 'Students', 'General public', 'People in struggle', 'Success seekers'],
        'default': 'General public',
      },
      {
        'key': 'message_style', 'label': 'Message Style', 'icon': '💪',
        'options': ['Personal story', 'Facts & statistics', 'Famous quotes', 'Direct challenge', 'Step-by-step guide'],
        'default': 'Personal story',
      },
    ],
    'News': [
      {
        'key': 'reporting_style', 'label': 'Reporting Style', 'icon': '📰',
        'options': ['Breaking news', 'In-depth investigation', 'Opinion & editorial', 'Feature story', 'Explainer journalism'],
        'default': 'Breaking news',
      },
      {
        'key': 'news_tone', 'label': 'News Tone', 'icon': '📡',
        'options': ['Urgent & immediate', 'Neutral & objective', 'Investigative', 'Conversational', 'Formal & authoritative'],
        'default': 'Neutral & objective',
      },
      {
        'key': 'presenter_format', 'label': 'Presenter Format', 'icon': '🎙️',
        'options': ['Anchor desk style', 'Field reporter', 'Documentary explainer', 'Podcast style', 'Interview format'],
        'default': 'Anchor desk style',
      },
    ],
    'Realistic': [
      {
        'key': 'character_gender', 'label': 'Main Character Gender', 'icon': '👤',
        'options': ['Male', 'Female', 'Non-binary', 'No main character'],
        'default': 'Male',
      },
      {
        'key': 'character_age', 'label': 'Character Age', 'icon': '🎂',
        'options': ['Child (5-12)', 'Teen (13-17)', 'Young adult (18-30)', 'Middle-aged (31-55)', 'Elderly (55+)'],
        'default': 'Young adult (18-30)',
      },
      {
        'key': 'character_accent', 'label': 'Character Voice & Accent', 'icon': '🗣️',
        'options': ['American English', 'British English', 'African accent', 'Asian accent', 'Latin accent', 'Australian', 'No dialogue'],
        'default': 'American English',
      },
      {
        'key': 'setting_type', 'label': 'Setting Type', 'icon': '🌍',
        'options': ['Urban city', 'Rural countryside', 'Indoor domestic', 'Outdoor nature', 'Fantasy realistic', 'Industrial', 'Coastal'],
        'default': 'Urban city',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialIdea != null) {
      _ideaCtrl.text = widget.initialIdea!;
      ref.read(generateFormProvider.notifier).setIdea(widget.initialIdea!);
    }
    // ── FIX: Skip AdMob on web ────────────────────────────────────────────
    if (!kIsWeb) AdService.instance.loadInterstitial();
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
        final user = ref.read(currentUserProvider);
        // ── FIX: Skip AdMob on web ────────────────────────────────────────
        if (!kIsWeb) await AdService.instance.showInterstitial(user);
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(generateFormProvider);
    final genState  = ref.watch(generationProvider);
    final user      = ref.watch(currentUserProvider);

    return Scaffold(
      body: StickyBannerAd(
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
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
                          position: Tween(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(anim),
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

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
            onPressed: _currentStep > 0 ? _prevStep : () => context.go('/home'),
          ),
          const SizedBox(width: 4),
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

  // ── Step Indicator ────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final isActive = i == _currentStep;
          final isDone   = i < _currentStep;
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
      case 0:  return _buildStep1(formState, user);
      case 1:  return _buildStep2(formState, user);
      case 2:  return _buildStep3(formState, user);
      default: return const SizedBox();
    }
  }

  // ── Step 1: Idea + Content Type + Platform ────────────────────────────────
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
          options: AppConfig.contentTypes
              .map((t) => SectionOption<String>(
                    value: t['name'],
                    label: t['name'],
                    emoji: t['icon'],
                    description: t['desc'],
                  ))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildContentTypeOptions(formState),
        const SizedBox(height: AppSpacing.lg),
        SectionSelector<String>(
          label: 'Target Platform',
          selected: formState.platform,
          onSelect: ref.read(generateFormProvider.notifier).setPlatform,
          options: AppConfig.platforms
              .map((p) => SectionOption<String>(
                    value: p['name'],
                    label: p['name'],
                    emoji: p['icon'],
                  ))
              .toList(),
        ),
      ],
    ).animate().fadeIn();
  }

  // ── Content Type Options Panel ────────────────────────────────────────────
  Widget _buildContentTypeOptions(formState) {
    final options = _contentTypeOptions[formState.contentType];
    if (options == null || options.isEmpty) return const SizedBox();

    final contentType     = formState.contentType as String;
    final selectedOptions = formState.contentTypeOptions as Map<String, String>;
    final accentColor     = _getContentTypeColor(contentType);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(contentType),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: accentColor.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_getContentTypeIcon(contentType),
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$contentType Settings',
                    style: AppTypography.titleMedium
                        .copyWith(color: accentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_getContentTypeSubtitle(contentType),
                style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.md),
            ...options.map((opt) {
              final key        = opt['key'] as String;
              final label      = opt['label'] as String;
              final icon       = opt['icon'] as String;
              final choices    = opt['options'] as List<String>;
              final defaultVal = opt['default'] as String;
              final selected   = selectedOptions[key] ?? defaultVal;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _buildOptionSelector(
                  key: key,
                  label: label,
                  icon: icon,
                  choices: choices,
                  selected: selected,
                  accentColor: accentColor,
                  onSelect: (val) => ref
                      .read(generateFormProvider.notifier)
                      .setContentTypeOption(key, val),
                ),
              );
            }),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.05),
    );
  }

  Widget _buildOptionSelector({
    required String key,
    required String label,
    required String icon,
    required List<String> choices,
    required String selected,
    required Color accentColor,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label, style: AppTypography.labelMedium),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: choices.map((choice) {
            final isSelected = selected == choice;
            return GestureDetector(
              onTap: () => onSelect(choice),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withOpacity(0.15)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: isSelected
                        ? accentColor.withOpacity(0.6)
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  choice,
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected
                        ? accentColor
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 2: Duration + Generator ──────────────────────────────────────────
  Widget _buildStep2(formState, user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('⏱️', 'Video Duration',
            'How long should your video be?'),
        const SizedBox(height: AppSpacing.sm),
        SectionSelector<int>(
          label: '',
          selected: formState.durationMinutes,
          onSelect: ref.read(generateFormProvider.notifier).setDuration,
          options: AppConfig.durations.map((d) {
            final isPaid   = d['paid'] == true;
            final isLocked = isPaid && (user?.isFree ?? true);
            return SectionOption<int>(
              value:       d['minutes'] as int,
              label:       d['label'] as String,
              description: d['desc'] as String,
              locked:      isLocked,
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _sectionTitle('🤖', 'AI Video Generator',
            'Which AI will you use to create the video?'),
        const SizedBox(height: AppSpacing.sm),
        ...AppConfig.generators.asMap().entries.map((e) {
          final gen          = e.value;
          final isSelected   = formState.generator == gen['name'];
          final clipDuration = gen['clip'] as int;
          final totalScenes  =
              _getDurationSeconds(formState.durationMinutes) ~/
                  clipDuration;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => ref
                  .read(generateFormProvider.notifier)
                  .setGenerator(gen['name']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.cardGradient : null,
                  color: isSelected ? null : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.6)
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected ? AppShadows.primary : null,
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 5 : 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(gen['name'] as String,
                              style: AppTypography.titleMedium),
                          Text(gen['desc'] as String,
                              style: AppTypography.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '$totalScenes scenes',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate(
                    delay: Duration(milliseconds: e.key * 50))
                .fadeIn()
                .slideX(begin: -0.05),
          );
        }),
      ],
    ).animate().fadeIn();
  }

  // ── Step 3: Voice-Over + Review ───────────────────────────────────────────
  Widget _buildStep3(formState, user) {
    final clipDuration    = _getClipDuration(formState.generator);
    final totalScenes     =
        _getDurationSeconds(formState.durationMinutes) ~/ clipDuration;
    final selectedOptions = formState.contentTypeOptions as Map<String, String>;
    final contentTypeOpts = _contentTypeOptions[formState.contentType] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('⚙️', 'Final Options',
            'Almost ready — one last step'),
        const SizedBox(height: AppSpacing.md),

        _buildFeatureCard(
          icon: '🎙️',
          title: 'Generate Voice-Over Script',
          subtitle:
              'Timed narration with [MM:SS] markers ready for ElevenLabs or any TTS tool',
          badge: 'OPTIONAL',
          badgeColor: AppColors.secondary,
          value: formState.generateVoiceOver,
          onChanged:
              ref.read(generateFormProvider.notifier).setGenerateVoiceOver,
        ),

        const SizedBox(height: AppSpacing.lg),
        _buildWhatYouGetBanner(totalScenes, clipDuration),
        const SizedBox(height: AppSpacing.lg),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.checklist_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Plan Summary',
                      style: AppTypography.titleMedium
                          .copyWith(color: AppColors.primary)),
                ],
              ),
              const Divider(height: 20),
              _reviewRow(
                Icons.lightbulb_outline,
                'Idea',
                formState.idea.length > 60
                    ? '${formState.idea.substring(0, 60)}...'
                    : formState.idea,
              ),
              _reviewRow(Icons.category_outlined, 'Type',
                  formState.contentType),
              _reviewRow(Icons.devices_outlined, 'Platform',
                  formState.platform),
              _reviewRow(Icons.timer_outlined, 'Duration',
                  '${formState.durationMinutes} minutes'),
              _reviewRow(Icons.movie_creation_outlined, 'Generator',
                  formState.generator),
              _reviewRow(Icons.slideshow_outlined, 'Total Scenes',
                  '$totalScenes clips × ${clipDuration}s'),
              _reviewRow(
                Icons.record_voice_over_outlined,
                'Voice-Over',
                formState.generateVoiceOver
                    ? '✅ Included'
                    : '— Not included',
              ),
              if (contentTypeOpts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Divider(
                  height: 20,
                  color: _getContentTypeColor(formState.contentType)
                      .withOpacity(0.3),
                ),
                Row(
                  children: [
                    Text(_getContentTypeIcon(formState.contentType),
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      '${formState.contentType} Settings',
                      style: AppTypography.labelMedium.copyWith(
                        color: _getContentTypeColor(
                            formState.contentType),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...contentTypeOpts.map((opt) {
                  final key        = opt['key'] as String;
                  final label      = opt['label'] as String;
                  final defaultVal = opt['default'] as String;
                  final value      = selectedOptions[key] ?? defaultVal;
                  return _reviewRow(Icons.tune_outlined, label, value);
                }),
              ],
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.98, 0.98)),

        const SizedBox(height: AppSpacing.md),

        // ── FIX: Web-aware info note ──────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
                color: AppColors.secondary.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  kIsWeb
                      ? 'Generation takes 30-90 seconds. Please keep this tab open.'
                      : 'Generation takes 30-90 seconds depending on video length. Please keep the app open.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),
      ],
    ).animate().fadeIn();
  }

  // ── Feature Card ──────────────────────────────────────────────────────────
  Widget _buildFeatureCard({
    required String icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: value
              ? AppColors.secondary.withOpacity(0.5)
              : AppColors.border,
          width: value ? 1.5 : 1,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: value
                  ? AppColors.secondary.withOpacity(0.15)
                  : AppColors.border.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child:
                  Text(icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: AppTypography.titleMedium),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                            color: badgeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        badge,
                        style: AppTypography.labelSmall.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.secondary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  // ── What You Get Banner ───────────────────────────────────────────────────
  Widget _buildWhatYouGetBanner(int totalScenes, int clipDuration) {
    final items = [
      {'icon': '📋', 'label': 'Full Script'},
      {'icon': '🎬', 'label': '$totalScenes Scenes'},
      {'icon': '🎥', 'label': 'Video Prompts'},
      {'icon': '🔍', 'label': 'SEO Pack'},
      {'icon': '#️⃣', 'label': 'Hashtags'},
      {'icon': '🖼️', 'label': 'Thumbnail'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.secondary.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (b) =>
                    AppColors.primaryGradient.createShader(b),
                child: const Text('✦',
                    style: TextStyle(
                        fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Text(
                "What's included in your plan",
                style: AppTypography.titleMedium
                    .copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.6),
                  borderRadius:
                      BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                      color: AppColors.border.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item['icon']!,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 5),
                    Text(
                      item['label']!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.05);
  }

  // ── Review Row ────────────────────────────────────────────────────────────
  Widget _reviewRow(IconData iconData, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label, style: AppTypography.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
      String emoji, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: AppTypography.headlineMedium),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: AppTypography.bodySmall),
      ],
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────
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
                onPressed: formState.isValid || _currentStep > 0
                    ? _nextStep
                    : null,
                fullWidth: true,
                height: 52,
              )
            : AppButton(
                label: genState.isGenerating
                    ? 'Generating your plan...'
                    : '✦  Generate Video Plan',
                onPressed:
                    genState.isGenerating ? null : _generate,
                fullWidth: true,
                height: 52,
                isLoading: genState.isGenerating,
              ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Color _getContentTypeColor(String ct) {
    const m = {
      'Educational':  Color(0xFF4FC3F7),
      'Narration':    Color(0xFFCE93D8),
      'Commentary':   Color(0xFFFFB74D),
      'Documentary':  Color(0xFF80CBC4),
      'Storytelling': Color(0xFFF48FB1),
      'Comedy':       Color(0xFFFFF176),
      'Horror':       Color(0xFFEF9A9A),
      'Motivational': Color(0xFFFFCC02),
      'News':         Color(0xFF90CAF9),
      'Realistic':    Color(0xFFA5D6A7),
    };
    return m[ct] ?? AppColors.primary;
  }

  String _getContentTypeIcon(String ct) {
    const m = {
      'Educational':  '🎓',
      'Narration':    '📖',
      'Commentary':   '💬',
      'Documentary':  '🎬',
      'Storytelling': '✨',
      'Comedy':       '😂',
      'Horror':       '👻',
      'Motivational': '🔥',
      'News':         '📰',
      'Realistic':    '📽️',
    };
    return m[ct] ?? '🎬';
  }

  String _getContentTypeSubtitle(String ct) {
    const m = {
      'Educational':  'Customize how your lesson is taught and who it\'s for',
      'Narration':    'Define narrator voice, accent and storytelling style',
      'Commentary':   'Set your opinion strength and presenter personality',
      'Documentary':  'Choose documentary style and evidence presentation',
      'Storytelling': 'Set genre, character type and story arc',
      'Comedy':       'Choose humor style, pacing and comedy format',
      'Horror':       'Set scare type, subgenre and atmosphere',
      'Motivational': 'Define energy level and target audience',
      'News':         'Set reporting style, tone and presenter format',
      'Realistic':    'Define character appearance, voice and setting',
    };
    return m[ct] ?? 'Customize your content type settings';
  }

  int _getDurationSeconds(int minutes) {
    const m = {1: 60, 3: 180, 5: 300, 10: 600, 20: 1200};
    return m[minutes] ?? 300;
  }

  int _getClipDuration(String generator) {
    const m = {
      'Runway': 5, 'Pika': 3,  'Kling': 10,
      'Sora': 15,  'Luma': 5,  'Haiper': 4, 'Other': 5,
    };
    return m[generator] ?? 5;
  }
}
