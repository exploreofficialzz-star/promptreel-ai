import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';

// ── Form State ────────────────────────────────────────────────────────────────
class GenerateFormState {
  final String idea;
  final String contentType;
  final String platform;
  final int durationMinutes;
  final String generator;
  final bool generateImagePrompts;
  final bool generateVoiceOver;
  final Map<String, String> contentTypeOptions;

  // Preview data
  final int? totalScenes;
  final int? clipDurationSeconds;

  const GenerateFormState({
    this.idea = '',
    this.contentType = 'Educational',
    this.platform = 'YouTube',
    this.durationMinutes = 5,
    this.generator = 'Kling',
    this.generateImagePrompts = false,
    this.generateVoiceOver = false,
    this.contentTypeOptions = const {},
    this.totalScenes,
    this.clipDurationSeconds,
  });

  GenerateFormState copyWith({
    String? idea,
    String? contentType,
    String? platform,
    int? durationMinutes,
    String? generator,
    bool? generateImagePrompts,
    bool? generateVoiceOver,
    Map<String, String>? contentTypeOptions,
    int? totalScenes,
    int? clipDurationSeconds,
  }) =>
      GenerateFormState(
        idea: idea ?? this.idea,
        contentType: contentType ?? this.contentType,
        platform: platform ?? this.platform,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        generator: generator ?? this.generator,
        generateImagePrompts:
            generateImagePrompts ?? this.generateImagePrompts,
        generateVoiceOver: generateVoiceOver ?? this.generateVoiceOver,
        contentTypeOptions: contentTypeOptions ?? this.contentTypeOptions,
        totalScenes: totalScenes ?? this.totalScenes,
        clipDurationSeconds: clipDurationSeconds ?? this.clipDurationSeconds,
      );

  bool get isValid => idea.trim().length >= 10;

  /// Returns a human-readable summary of selected content type options
  String get contentTypeOptionsSummary {
    if (contentTypeOptions.isEmpty) return '';
    return contentTypeOptions.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }
}

class GenerateFormNotifier extends StateNotifier<GenerateFormState> {
  GenerateFormNotifier() : super(const GenerateFormState());

  void setIdea(String v) => state = state.copyWith(idea: v);

  void setContentType(String v) => state = state.copyWith(
        contentType: v,
        // Reset options when content type changes
        contentTypeOptions: {},
      );

  void setPlatform(String v) => state = state.copyWith(platform: v);
  void setDuration(int v) => state = state.copyWith(durationMinutes: v);
  void setGenerator(String v) => state = state.copyWith(generator: v);
  void setGenerateImagePrompts(bool v) =>
      state = state.copyWith(generateImagePrompts: v);
  void setGenerateVoiceOver(bool v) =>
      state = state.copyWith(generateVoiceOver: v);

  void setContentTypeOption(String key, String value) {
    final updated = Map<String, String>.from(state.contentTypeOptions);
    updated[key] = value;
    state = state.copyWith(contentTypeOptions: updated);
  }

  void setPreview(
      {required int totalScenes, required int clipDurationSeconds}) {
    state = state.copyWith(
        totalScenes: totalScenes, clipDurationSeconds: clipDurationSeconds);
  }

  void reset() => state = const GenerateFormState();
}

final generateFormProvider =
    StateNotifierProvider<GenerateFormNotifier, GenerateFormState>(
  (_) => GenerateFormNotifier(),
);

// ── Generation Result State ───────────────────────────────────────────────────
class GenerationState {
  final bool isGenerating;
  final ProjectModel? project;
  final String? error;
  final String? aiProvider;

  const GenerationState({
    this.isGenerating = false,
    this.project,
    this.error,
    this.aiProvider,
  });

  GenerationState copyWith({
    bool? isGenerating,
    ProjectModel? project,
    String? error,
    String? aiProvider,
  }) =>
      GenerationState(
        isGenerating: isGenerating ?? this.isGenerating,
        project: project ?? this.project,
        error: error,
        aiProvider: aiProvider ?? this.aiProvider,
      );
}

class GenerationNotifier extends StateNotifier<GenerationState> {
  final ApiService _api;

  GenerationNotifier(this._api) : super(const GenerationState());

  Future<bool> generate(GenerateFormState form) async {
    if (!form.isValid) return false;
    state = const GenerationState(isGenerating: true);

    try {
      final response = await _api.generateVideoplan(
        idea: form.idea,
        contentType: form.contentType,
        platform: form.platform,
        durationMinutes: form.durationMinutes,
        generator: form.generator,
        generateImagePrompts: form.generateImagePrompts,
        generateVoiceOver: form.generateVoiceOver,
        contentTypeOptions: form.contentTypeOptions,
      );

      final project = ProjectModel(
        id: response['project_id'] ?? 0,
        title: response['title'] ?? '',
        idea: form.idea,
        contentType: form.contentType,
        platform: form.platform,
        durationMinutes: form.durationMinutes,
        generator: form.generator,
        generateImagePrompts: form.generateImagePrompts,
        generateVoiceOver: form.generateVoiceOver,
        status: response['status'] ?? 'completed',
        totalScenes: response['total_scenes'] ?? 0,
        clipDurationSeconds: response['clip_duration_seconds'] ?? 5,
        aiProviderUsed: response['ai_provider'],
        result: response['result'] != null
            ? VideoResult.fromJson(response['result'])
            : null,
      );

      state = GenerationState(
        isGenerating: false,
        project: project,
        aiProvider: response['ai_provider'],
      );
      return true;
    } catch (e) {
      state = GenerationState(
        isGenerating: false,
        error: ApiService.extractError(e),
      );
      return false;
    }
  }

  void clear() => state = const GenerationState();
}

final generationProvider =
    StateNotifierProvider<GenerationNotifier, GenerationState>((ref) {
  return GenerationNotifier(ref.read(apiServiceProvider));
});
