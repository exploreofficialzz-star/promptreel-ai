import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/project_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/projects_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/prompt_copy_card.dart';
import '../../widgets/ads/native_ad_card.dart';
import '../../widgets/ads/rewarded_export_gate.dart';
import '../../widgets/affiliate/affiliate_tab.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final int projectId;
  final ProjectModel? project;

  const ResultsScreen({
    super.key,
    required this.projectId,
    this.project,
  });

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ProjectModel? _project;
  bool _isLoading    = false;
  bool _isDownloading = false;

  final _tabs = [
    {'label': 'Overview', 'icon': Icons.dashboard_outlined},
    {'label': 'Script',   'icon': Icons.article_outlined},
    {'label': 'Scenes',   'icon': Icons.movie_outlined},
    {'label': 'Prompts',  'icon': Icons.smart_toy_outlined},
    {'label': 'SEO',      'icon': Icons.search_outlined},
    {'label': 'Export',   'icon': Icons.download_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _project = widget.project;

    // Only load from API if we don't already have the project data
    if (_project == null || _project!.result == null) {
      _loadProject();
    }
  }

  // ── Load Project ──────────────────────────────────────────────────────────
  Future<void> _loadProject() async {
    setState(() => _isLoading = true);

    try {
      // 1. Try API first
      final p = await ref.read(apiServiceProvider)
          .getProject(widget.projectId);
      if (mounted) {
        setState(() {
          _project   = p;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // API failed — fall through to cache
    }

    // 2. Try local projects provider cache
    if (mounted) {
      final cached = ref.read(projectsProvider).projects
          .where((p) => p.id == widget.projectId)
          .firstOrNull;

      setState(() {
        _project   = cached;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Download ZIP ──────────────────────────────────────────────────────────
  Future<void> _downloadZip() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    _showSnack('Preparing ZIP package...', isInfo: true);

    try {
      final bytes = await ref
          .read(apiServiceProvider)
          .exportProjectZip(_project!.id);

      if (bytes.isEmpty) {
        _showSnack('Export failed — no data received.', isError: true);
        return;
      }

      final dir      = await getTemporaryDirectory();
      final filename =
          'promptreel_${_project!.id}_${_project!.platform.toLowerCase()}.zip';
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/zip')],
        subject: 'PromptReel AI — ${_project!.title}',
        text:    'Your complete video production package from PromptReel AI!',
      );
    } catch (e) {
      if (mounted) {
        _showSnack('Download failed: ${ApiService.extractError(e)}',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ── Download Individual File ──────────────────────────────────────────────
  Future<void> _downloadFile(String type) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    _showSnack('Preparing $type file...', isInfo: true);

    try {
      final api = ref.read(apiServiceProvider);
      final dir = await getTemporaryDirectory();

      if (type == 'script') {
        final content = await api.exportProjectScript(_project!.id);
        if (content.isEmpty) {
          _showSnack('Script is empty.', isError: true);
          return;
        }
        final file = File('${dir.path}/script_${_project!.id}.txt');
        await file.writeAsString(content);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/plain')],
          subject: 'PromptReel Script — ${_project!.title}',
        );
      } else if (type == 'srt') {
        final content = await api.exportProjectSrt(_project!.id);
        if (content.isEmpty) {
          _showSnack('Subtitles are empty.', isError: true);
          return;
        }
        final file =
            File('${dir.path}/subtitles_${_project!.id}.srt');
        await file.writeAsString(content);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/srt')],
          subject: 'PromptReel Subtitles — ${_project!.title}',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Download failed: ${ApiService.extractError(e)}',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _showSnack(String msg,
      {bool isError = false, bool isInfo = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError
          ? AppColors.error
          : isInfo
              ? AppColors.surfaceElevated
              : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoading();
    if (_project == null) return _buildError();

    final result = _project!.result;
    if (result == null) return _buildError();

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(result),
                    _buildScriptTab(result),
                    _buildScenesTab(result),
                    _buildPromptsTab(result),
                    _buildSeoTab(result),
                    _buildExportTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/home'),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _project!.result?.titles.primary ?? _project!.title,
                  style: AppTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    _Chip(_project!.platform),
                    const SizedBox(width: 6),
                    _Chip(_project!.generator),
                    const SizedBox(width: 6),
                    _Chip('${_project!.totalScenes} scenes'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                  color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Text('Ready',
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.success)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: _tabs
            .map((t) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t['icon'] as IconData, size: 14),
                      const SizedBox(width: 6),
                      Text(t['label'] as String),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  // ── Overview Tab ──────────────────────────────────────────────────────────
  Widget _buildOverviewTab(VideoResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('🎯', 'Viral Hook'),
          PromptCopyCard(
            label: 'HOOK',
            content: result.viralHook,
            accentColor: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionHeader('🎬', 'Titles'),
          AppCard(
            child: Column(
              children: [
                _titleRow('▶️ YouTube', result.titles.youtube),
                _divider(),
                _titleRow('🎵 TikTok', result.titles.tiktok),
                _divider(),
                _titleRow('📸 Instagram', result.titles.instagram),
                _divider(),
                _titleRow('📱 Shorts', result.titles.shorts),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionHeader('🖼️', 'Thumbnail Prompt'),
          PromptCopyCard(
            label: 'THUMBNAIL',
            content: result.thumbnailPrompt,
            accentColor: AppColors.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          if (result.productionNotes != null) ...[
            _sectionHeader('📋', 'Production Notes'),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statBadge(
                          '${result.productionNotes!.totalScenesNeeded}',
                          'Total Scenes'),
                      const SizedBox(width: 8),
                      _statBadge(
                          '${result.productionNotes!.clipDurationSeconds}s',
                          'Per Clip'),
                      const SizedBox(width: 8),
                      _statBadge(
                          '${_project!.durationMinutes}min',
                          'Duration'),
                    ],
                  ),
                  if (result.productionNotes!.proTips.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Pro Tips',
                        style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    ...result.productionNotes!.proTips
                        .map((tip) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('💡 ',
                                      style:
                                          TextStyle(fontSize: 12)),
                                  Expanded(
                                    child: Text(tip,
                                        style: AppTypography
                                            .bodySmall
                                            .copyWith(
                                                color: AppColors
                                                    .textPrimary)),
                                  ),
                                ],
                              ),
                            )),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn();
  }

  // ── Script Tab ────────────────────────────────────────────────────────────
  Widget _buildScriptTab(VideoResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      child: Column(
        children: [
          PromptCopyCard(
            label:
                'FULL SCRIPT — ${_project!.durationMinutes} MINUTES',
            content: result.fullScript,
            maxLines: 20,
          ),
          if (result.voiceOverScript != null &&
              result.voiceOverScript!.isNotEmpty &&
              result.voiceOverScript != 'Not requested') ...[
            const SizedBox(height: AppSpacing.md),
            PromptCopyCard(
              label: 'VOICE-OVER SCRIPT (TIMED)',
              content: result.voiceOverScript!,
              isMonospace: true,
              accentColor: AppColors.secondary,
              maxLines: 20,
            ),
          ],
        ],
      ),
    ).animate().fadeIn();
  }

  // ── Scenes Tab ────────────────────────────────────────────────────────────
  Widget _buildScenesTab(VideoResult result) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: result.sceneBreakdown.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final scene = result.sceneBreakdown[i];
        return _SceneCard(scene: scene)
            .animate(
                delay: Duration(
                    milliseconds: (i * 40).clamp(0, 600)))
            .fadeIn()
            .slideY(begin: 0.1);
      },
    );
  }

  // ── Prompts Tab ───────────────────────────────────────────────────────────
  Widget _buildPromptsTab(VideoResult result) {
    return DefaultTabController(
      length: result.imagePrompts.isEmpty ? 1 : 2,
      child: Column(
        children: [
          if (result.imagePrompts.isNotEmpty)
            TabBar(
              tabs: [
                const Tab(text: 'Video Prompts'),
                Tab(text:
                    'Image Prompts (${result.imagePrompts.length})'),
              ],
            ),
          Expanded(
            child: result.imagePrompts.isEmpty
                ? _buildVideoPromptsList(result.videoPrompts)
                : TabBarView(
                    children: [
                      _buildVideoPromptsList(result.videoPrompts),
                      _buildImagePromptsList(result.imagePrompts),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPromptsList(List<VideoPromptItem> prompts) {
    final user   = ref.read(currentUserProvider);
    final isPaid = user?.isPaid ?? false;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        GeneratorAffiliateSuggestion(
            generatorName: _project!.generator),
        const SizedBox(height: 8),
        ...NativeAdInjector.buildList(
          items: prompts,
          isPaidUser: isPaid,
          frequency: 8,
          builder: (p, i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PromptCopyCard(
              label: 'SCENE ${p.sceneNumber} • ${p.duration}',
              content: p.prompt,
              badge: p.cameraWork,
              accentColor: AppColors.primary,
            )
                .animate(
                    delay: Duration(
                        milliseconds: (i * 40).clamp(0, 500)))
                .fadeIn(),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePromptsList(List<ImagePromptItem> prompts) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: prompts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = prompts[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scene ${p.sceneNumber}',
                style: AppTypography.titleMedium),
            if (p.midjourney != null) ...[
              const SizedBox(height: 6),
              PromptCopyCard(
                label: 'MIDJOURNEY',
                content: p.midjourney!,
                accentColor: const Color(0xFF5865F2),
              ),
            ],
            if (p.leonardo != null) ...[
              const SizedBox(height: 6),
              PromptCopyCard(
                label: 'LEONARDO AI',
                content: p.leonardo!,
                accentColor: AppColors.primary,
              ),
            ],
            if (p.stableDiffusion != null) ...[
              const SizedBox(height: 6),
              PromptCopyCard(
                label: 'STABLE DIFFUSION',
                content: p.stableDiffusion!,
              ),
            ],
            if (p.dallE != null) ...[
              const SizedBox(height: 6),
              PromptCopyCard(
                label: 'DALL-E',
                content: p.dallE!,
                accentColor: const Color(0xFF10A37F),
              ),
            ],
          ],
        );
      },
    );
  }

  // ── SEO Tab ───────────────────────────────────────────────────────────────
  Widget _buildSeoTab(VideoResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      child: Column(
        children: [
          PromptCopyCard(
              label: 'SEO TITLE',
              content: result.youtubeSeo.title),
          const SizedBox(height: AppSpacing.sm),
          PromptCopyCard(
            label: 'DESCRIPTION',
            content: result.youtubeSeo.description,
            maxLines: 8,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TAGS',
                    style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 0.8)),
                const SizedBox(height: 10),
                TagsDisplay(tags: result.youtubeSeo.tags),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text('HASHTAGS',
                        style: AppTypography.labelMedium.copyWith(
                            color: AppColors.secondary,
                            letterSpacing: 0.8)),
                    Text('${result.hashtags.all.length} total',
                        style: AppTypography.bodySmall),
                  ],
                ),
                const SizedBox(height: 10),
                TagsDisplay(
                    tags: result.hashtags.all,
                    color: AppColors.secondary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PromptCopyCard(
            label: 'SUBTITLES (SRT)',
            content: result.subtitleScript,
            isMonospace: true,
            accentColor: AppColors.textMuted,
            maxLines: 10,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // ── Export Tab ────────────────────────────────────────────────────────────
  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlowCard(
            glowColor: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📦',
                    style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text('Complete Package',
                    style: AppTypography.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  'ZIP includes: scripts, video prompts, SEO pack, '
                  'hashtags, thumbnail prompt, subtitles, and production notes.',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                RewardedExportGate(
                  exportLabel: 'Download ZIP Package',
                  onUnlocked: _downloadZip,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Individual Files',
              style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),

          // ── Script ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: _isDownloading
                  ? null
                  : () => _downloadFile('script'),
              child: Row(
                children: [
                  Icon(Icons.article_outlined,
                      color: _isDownloading
                          ? AppColors.textMuted
                          : AppColors.primary,
                      size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text('Script (.txt)',
                          style: AppTypography.titleMedium)),
                  _isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary))
                      : const Icon(Icons.download_outlined,
                          size: 16,
                          color: AppColors.textMuted),
                ],
              ),
            ),
          ),

          // ── SRT ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              onTap: _isDownloading
                  ? null
                  : () => _downloadFile('srt'),
              child: Row(
                children: [
                  Icon(Icons.subtitles_outlined,
                      color: _isDownloading
                          ? AppColors.textMuted
                          : AppColors.secondary,
                      size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text('Subtitles (.srt)',
                          style: AppTypography.titleMedium)),
                  _isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary))
                      : const Icon(Icons.download_outlined,
                          size: 16,
                          color: AppColors.textMuted),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
          InlineAffiliateCard(
            tool: const AffiliateTool(
              name: 'ElevenLabs',
              tagline:
                  'Turn your voice-over script into realistic AI audio',
              emoji: '🎙️',
              url: 'https://elevenlabs.io',
              accentColor: Color(0xFFFF6B35),
              badge: 'Recommended',
              category: 'voice',
            ),
            contextLabel:
                '🎙️ Need audio for your voice-over script?',
          ),
          InlineAffiliateCard(
            tool: const AffiliateTool(
              name: 'CapCut',
              tagline: 'Assemble your AI clips with free editing',
              emoji: '✂️',
              url: 'https://capcut.com',
              accentColor: Color(0xFF4CAF7D),
              badge: 'Free',
              category: 'editing',
            ),
            contextLabel: '✂️ Ready to assemble your clips?',
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionHeader(String emoji, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(title, style: AppTypography.titleMedium),
        ],
      ),
    );
  }

  Widget _titleRow(String platform, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(platform,
                style: AppTypography.bodySmall),
          ),
          Expanded(
            child: Text(title,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1);

  Widget _statBadge(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTypography.titleMedium
                    .copyWith(color: AppColors.primary)),
            Text(label, style: AppTypography.labelSmall),
          ],
        ),
      ),
    );
  }

  // ── Loading / Error States ────────────────────────────────────────────────
  Widget _buildLoading() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Loading project...',
                  style:
                      TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕',
                  style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('Project not found',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18)),
              const SizedBox(height: 8),
              const Text(
                'The project may have been deleted\nor failed to load.',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Go Home',
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Scene Card ───────────────────────────────────────────────────────────────
class _SceneCard extends StatefulWidget {
  final SceneItem scene;
  const _SceneCard({required this.scene});

  @override
  State<_SceneCard> createState() => _SceneCardState();
}

class _SceneCardState extends State<_SceneCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.scene.sceneNumber}',
                        style: AppTypography.labelLarge.copyWith(
                            color: Colors.black, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(widget.scene.title,
                            style: AppTypography.titleMedium),
                        Text(
                          '${widget.scene.timeStart} → ${widget.scene.timeEnd}  •  ${widget.scene.mood}',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (_expanded)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 12),
                    _sceneDetail('🎥 Visual',
                        widget.scene.visualDescription),
                    const SizedBox(height: 8),
                    _sceneDetail('🎙️ Narration',
                        widget.scene.narrationText),
                    if (widget.scene.transition != null) ...[
                      const SizedBox(height: 8),
                      _sceneDetail('↪️ Transition',
                          widget.scene.transition!),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sceneDetail(String label, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(content,
            style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary, height: 1.6)),
      ],
    );
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String text;
  const _Chip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(text, style: AppTypography.labelSmall),
    );
  }
}
