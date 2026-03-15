import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';

class ProjectsState {
  final List<ProjectModel> projects;
  final bool isLoading;
  final String? error;
  final int total;
  final int page;
  final int pages;
  final Map<String, dynamic> stats;

  const ProjectsState({
    this.projects = const [],
    this.isLoading = false,
    this.error,
    this.total = 0,
    this.page = 1,
    this.pages = 1,
    this.stats = const {},
  });

  ProjectsState copyWith({
    List<ProjectModel>? projects,
    bool? isLoading,
    String? error,
    int? total,
    int? page,
    int? pages,
    Map<String, dynamic>? stats,
  }) =>
      ProjectsState(
        projects: projects ?? this.projects,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        total: total ?? this.total,
        page: page ?? this.page,
        pages: pages ?? this.pages,
        stats: stats ?? this.stats,
      );
}

class ProjectsNotifier extends StateNotifier<ProjectsState> {
  final ApiService _api;

  ProjectsNotifier(this._api) : super(const ProjectsState());

  Future<void> load({String? search, int page = 1}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.getProjects(page: page, search: search);
      final projects = (data['projects'] as List)
          .map((e) => ProjectModel.fromJson(e))
          .toList();
      state = state.copyWith(
        projects: page == 1 ? projects : [...state.projects, ...projects],
        isLoading: false,
        total: data['total'] ?? 0,
        page: data['page'] ?? 1,
        pages: data['pages'] ?? 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ApiService.extractError(e));
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _api.getStats();
      state = state.copyWith(stats: stats);
    } catch (_) {}
  }

  Future<bool> delete(int id) async {
    try {
      await _api.deleteProject(id);
      state = state.copyWith(
        projects: state.projects.where((p) => p.id != id).toList(),
        total: state.total - 1,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: ApiService.extractError(e));
      return false;
    }
  }

  void addProject(ProjectModel project) {
    state = state.copyWith(
      projects: [project, ...state.projects],
      total: state.total + 1,
    );
  }

  void clear() => state = const ProjectsState();
}

final projectsProvider = StateNotifierProvider<ProjectsNotifier, ProjectsState>((ref) {
  return ProjectsNotifier(ref.read(apiServiceProvider));
});

final projectDetailProvider = FutureProvider.family<ProjectModel, int>((ref, id) async {
  return ref.read(apiServiceProvider).getProject(id);
});
