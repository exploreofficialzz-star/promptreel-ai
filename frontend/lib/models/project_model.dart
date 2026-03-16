class SceneItem {
  final int sceneNumber;
  final String timeStart;
  final String timeEnd;
  final String title;
  final String visualDescription;
  final String narrationText;
  final String mood;
  final String? bRollSuggestion;
  final String? transition;

  const SceneItem({
    required this.sceneNumber,
    required this.timeStart,
    required this.timeEnd,
    required this.title,
    required this.visualDescription,
    required this.narrationText,
    required this.mood,
    this.bRollSuggestion,
    this.transition,
  });

  factory SceneItem.fromJson(Map<String, dynamic> json) => SceneItem(
        sceneNumber: json['scene_number'] ?? 0,
        timeStart: json['time_start'] ?? '',
        timeEnd: json['time_end'] ?? '',
        title: json['title'] ?? '',
        visualDescription: json['visual_description'] ?? '',
        narrationText: json['narration_text'] ?? '',
        mood: json['mood'] ?? '',
        bRollSuggestion: json['b_roll_suggestion'],
        transition: json['transition'],
      );
}

class VideoPromptItem {
  final int sceneNumber;
  final String prompt;
  final String? negativePrompt;
  final String? cameraWork;
  final String? lighting;
  final List<String> styleTags;
  final String duration;

  const VideoPromptItem({
    required this.sceneNumber,
    required this.prompt,
    this.negativePrompt,
    this.cameraWork,
    this.lighting,
    this.styleTags = const [],
    this.duration = '5s',
  });

  factory VideoPromptItem.fromJson(Map<String, dynamic> json) => VideoPromptItem(
        sceneNumber: json['scene_number'] ?? 0,
        prompt: json['prompt'] ?? '',
        negativePrompt: json['negative_prompt'],
        cameraWork: json['camera_work'],
        lighting: json['lighting'],
        styleTags: List<String>.from(json['style_tags'] ?? []),
        duration: json['duration'] ?? '5s',
      );
}

class ImagePromptItem {
  final int sceneNumber;
  final String? midjourney;
  final String? stableDiffusion;
  final String? leonardo;
  final String? dallE;
  final String? purpose;
  final String? styleReference;

  const ImagePromptItem({
    required this.sceneNumber,
    this.midjourney,
    this.stableDiffusion,
    this.leonardo,
    this.dallE,
    this.purpose,
    this.styleReference,
  });

  factory ImagePromptItem.fromJson(Map<String, dynamic> json) => ImagePromptItem(
        sceneNumber: json['scene_number'] ?? 0,
        midjourney: json['midjourney'],
        stableDiffusion: json['stable_diffusion'],
        leonardo: json['leonardo'],
        dallE: json['dall_e'],
        purpose: json['purpose'],
        styleReference: json['style_reference'],
      );
}

class YouTubeSeo {
  final String title;
  final String description;
  final List<String> tags;
  final String? category;

  const YouTubeSeo({
    required this.title,
    required this.description,
    required this.tags,
    this.category,
  });

  factory YouTubeSeo.fromJson(Map<String, dynamic> json) => YouTubeSeo(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        tags: List<String>.from(json['tags'] ?? []),
        category: json['category'],
      );
}

class HashtagSet {
  final List<String> primary;
  final List<String> secondary;
  final List<String> niche;
  final List<String> trending;

  const HashtagSet({
    required this.primary,
    required this.secondary,
    required this.niche,
    required this.trending,
  });

  factory HashtagSet.fromJson(dynamic json) {
    if (json is List) {
      return HashtagSet(
        primary: List<String>.from(json),
        secondary: [],
        niche: [],
        trending: [],
      );
    }
    final map = json as Map<String, dynamic>;
    return HashtagSet(
      primary: List<String>.from(map['primary'] ?? []),
      secondary: List<String>.from(map['secondary'] ?? []),
      niche: List<String>.from(map['niche'] ?? []),
      trending: List<String>.from(map['trending'] ?? []),
    );
  }

  List<String> get all => [...primary, ...secondary, ...niche, ...trending];
}

class VideoTitles {
  final String youtube;
  final String tiktok;
  final String instagram;
  final String facebook;
  final String shorts;
  final String primary;

  const VideoTitles({
    required this.youtube,
    required this.tiktok,
    required this.instagram,
    required this.facebook,
    required this.shorts,
    required this.primary,
  });

  factory VideoTitles.fromJson(Map<String, dynamic> json) => VideoTitles(
        youtube: json['youtube'] ?? '',
        tiktok: json['tiktok'] ?? '',
        instagram: json['instagram'] ?? '',
        facebook: json['facebook'] ?? '',
        shorts: json['shorts'] ?? '',
        primary: json['primary'] ?? json['youtube'] ?? '',
      );
}

class ProductionNotes {
  final int totalScenesNeeded;
  final int detailedScenesProvided;
  final int clipDurationSeconds;
  final List<String> proTips;
  final String? recommendedEditingTool;

  const ProductionNotes({
    required this.totalScenesNeeded,
    required this.detailedScenesProvided,
    required this.clipDurationSeconds,
    required this.proTips,
    this.recommendedEditingTool,
  });

  factory ProductionNotes.fromJson(Map<String, dynamic> json) => ProductionNotes(
        totalScenesNeeded: json['total_scenes_needed'] ?? 0,
        detailedScenesProvided: json['detailed_scenes_provided'] ?? 0,
        clipDurationSeconds: json['clip_duration_seconds'] ?? 5,
        proTips: List<String>.from(json['pro_tips'] ?? []),
        recommendedEditingTool: json['recommended_editing_tool'],
      );
}

class VideoResult {
  final VideoTitles titles;
  final String viralHook;
  final String fullScript;
  final List<SceneItem> sceneBreakdown;
  final List<VideoPromptItem> videoPrompts;
  final List<ImagePromptItem> imagePrompts;
  final String? voiceOverScript;
  final YouTubeSeo youtubeSeo;
  final HashtagSet hashtags;
  final String thumbnailPrompt;
  final String subtitleScript;
  final ProductionNotes? productionNotes;

  const VideoResult({
    required this.titles,
    required this.viralHook,
    required this.fullScript,
    required this.sceneBreakdown,
    required this.videoPrompts,
    required this.imagePrompts,
    this.voiceOverScript,
    required this.youtubeSeo,
    required this.hashtags,
    required this.thumbnailPrompt,
    required this.subtitleScript,
    this.productionNotes,
  });

  factory VideoResult.fromJson(Map<String, dynamic> json) => VideoResult(
        titles: VideoTitles.fromJson(json['titles'] ?? {}),
        viralHook: json['viral_hook'] ?? '',
        fullScript: json['full_script'] ?? '',
        sceneBreakdown: (json['scene_breakdown'] as List? ?? [])
            .map((e) => SceneItem.fromJson(e))
            .toList(),
        videoPrompts: (json['video_prompts'] as List? ?? [])
            .map((e) => VideoPromptItem.fromJson(e))
            .toList(),
        imagePrompts: (json['image_prompts'] as List? ?? [])
            .map((e) => ImagePromptItem.fromJson(e))
            .toList(),
        voiceOverScript: json['voice_over_script'],
        youtubeSeo: YouTubeSeo.fromJson(json['youtube_seo'] ?? {}),
        hashtags: HashtagSet.fromJson(json['hashtags'] ?? {}),
        thumbnailPrompt: json['thumbnail_prompt'] ?? '',
        subtitleScript: json['subtitle_script'] ?? '',
        productionNotes: json['production_notes'] != null
            ? ProductionNotes.fromJson(json['production_notes'])
            : null,
      );
}

class ProjectModel {
  final int id;
  final String title;
  final String idea;
  final String contentType;
  final String platform;
  final int durationMinutes;
  final String generator;
  final bool generateImagePrompts;
  final bool generateVoiceOver;
  final String status;
  final int totalScenes;
  final int clipDurationSeconds;
  final String? aiProviderUsed;
  final String? createdAt;
  final VideoResult? result;

  const ProjectModel({
    required this.id,
    required this.title,
    required this.idea,
    required this.contentType,
    required this.platform,
    required this.durationMinutes,
    required this.generator,
    required this.generateImagePrompts,
    required this.generateVoiceOver,
    required this.status,
    required this.totalScenes,
    required this.clipDurationSeconds,
    this.aiProviderUsed,
    this.createdAt,
    this.result,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) => ProjectModel(
        id: json['id'] ?? 0,
        title: json['title'] ?? '',
        idea: json['idea'] ?? '',
        contentType: json['content_type'] ?? '',
        platform: json['platform'] ?? '',
        durationMinutes: json['duration_minutes'] ?? 5,
        generator: json['generator'] ?? '',
        generateImagePrompts: json['generate_image_prompts'] ?? false,
        generateVoiceOver: json['generate_voice_over'] ?? false,
        status: json['status'] ?? 'pending',
        totalScenes: json['total_scenes'] ?? 0,
        clipDurationSeconds: json['clip_duration_seconds'] ?? 5,
        aiProviderUsed: json['ai_provider_used'],
        createdAt: json['created_at'],
        result: json['result'] != null ? VideoResult.fromJson(json['result']) : null,
      );

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing';
}
