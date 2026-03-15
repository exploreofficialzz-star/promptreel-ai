import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../providers/projects_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';
import '../../models/project_model.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearch(),
              Expanded(
                child: state.isLoading && state.projects.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : state.projects.isEmpty
                        ? _buildEmpty()
                        : _buildList(state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/home'),
          ),
          const SizedBox(width: 8),
          Text('My Projects', style: AppTypography.headlineLarge),
          const Spacer(),
          AppButton(
            label: '+ New',
            onPressed: () => context.go('/create'),
            height: 36,
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchCtrl,
        style: AppTypography.bodyLarge.copyWith(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search projects...',
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 16, color: AppColors.textMuted),
                  onPressed: () {
                    _searchCtrl.clear();
                    ref.read(projectsProvider.notifier).load();
                  },
                )
              : null,
        ),
        onChanged: (v) {
          if (v.length > 2 || v.isEmpty) {
            ref.read(projectsProvider.notifier).load(search: v.isEmpty ? null : v);
          }
        },
      ),
    );
  }

  Widget _buildList(projectsState) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: projectsState.projects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final project = projectsState.projects[i];
        return _ProjectCard(project: project, onDelete: () => _deleteProject(project.id))
            .animate(delay: Duration(milliseconds: (i * 50).clamp(0, 400)))
            .fadeIn()
            .slideY(begin: 0.1);
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎬', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('No projects yet', style: AppTypography.headlineMedium),
          const SizedBox(height: 8),
          Text('Create your first video plan', style: AppTypography.bodySmall),
          const SizedBox(height: 24),
          AppButton(label: 'Create Now', onPressed: () => context.go('/create')),
        ],
      ),
    );
  }

  Future<void> _deleteProject(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('This will permanently delete this project and all its data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(projectsProvider.notifier).delete(id);
    }
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onDelete;

  const _ProjectCard({required this.project, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go('/results/${project.id}', extra: project),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(_getPlatformEmoji(project.platform), style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.title, style: AppTypography.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    _chip(project.platform),
                    _chip(project.contentType),
                    _chip('${project.durationMinutes}min'),
                    _chip('${project.totalScenes} scenes'),
                    _chip(project.generator),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  project.createdAt != null ? _formatDate(project.createdAt!) : '',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'delete' ? onDelete() : null,
            color: AppColors.surfaceElevated,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: AppColors.error)),
                ],
              )),
            ],
            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(text, style: AppTypography.labelSmall),
    );
  }

  String _getPlatformEmoji(String platform) {
    switch (platform) {
      case 'YouTube': return '▶️';
      case 'TikTok': return '🎵';
      case 'Instagram': return '📸';
      case 'Facebook': return '👍';
      default: return '📱';
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
