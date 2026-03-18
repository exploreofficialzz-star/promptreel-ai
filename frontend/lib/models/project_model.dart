// ─── Character Bible Models ───────────────────────────────────────────────────
class CharacterAppearance {
  final String size;
  final String colors;
  final String markings;
  final String eyes;
  final String distinctiveFeatures;
  final String accessories;

  const CharacterAppearance({
    required this.size,
    required this.colors,
    required this.markings,
    required this.eyes,
    required this.distinctiveFeatures,
    required this.accessories,
  });

  factory CharacterAppearance.fromJson(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    return CharacterAppearance(
      size: json['size']?.toString() ?? '',
      colors: json['colors']?.toString() ?? '',
      markings: json['markings']?.toString() ?? '',
      eyes: json['eyes']?.toString() ?? '',
      distinctiveFeatures: json['distinctive_features']?.toString() ?? '',
      accessories: json['accessories']?.toString() ?? '',
    );
  }
}

class CharacterBibleEntry {
  final String id;
  final String name;
  final String type;
  final CharacterAppearance? appearance;
  final String movementStyle;
  final String personalityVisual;

  const CharacterBibleEntry({
    required this.id,
    required this.name,
    required this.type,
    this.appearance,
    required this.movementStyle,
    required this.personalityVisual,
  });

  factory CharacterBibleEntry.fromJson(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    return CharacterBibleEntry(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      appearance: json['appearance'] != null
          ? CharacterAppearance.fromJson(json['appearance'])
          : null,
      movementStyle: json['movement_style']?.toString() ?? '',
      personalityVisual: json['personality_visual']?.toString() ?? '',
    );
  }
}

class LocationEntry {
  final String id;
  final String name;
  final String description;
  final String lighting;
  final String atmosphere;

  const LocationEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.lighting,
    required this.atmosphere,
  });

  factory LocationEntry.fromJson(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    return LocationEntry(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      lighting: json['lighting']?.toString() ?? '',
      atmosphere: json['atmosphere']?.toString() ?? '',
    );
  }
}

class VisualStyle {
  final String style;
  final String colorGrading;
  final String lightingMood;
  final String consistencySeed;

  const VisualStyle({
    required this.style,
    required this.colorGrading,
    required this.lightingMood,
    required this.consistencySeed,
  });

  factory VisualStyle.fromJson(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    return VisualStyle(
      style: json['style']?.toString() ?? '',
      colorGrading: json['color_grading']?.toString() ?? '',
      lightingMood: json['lighting_mood']?.toString() ?? '',
      consistencySeed: json['consistency_seed']?.toString() ?? '',
    );
  }
}

class CharacterBible {
  final List<CharacterBibleEntry> characters;
  final List<LocationEntry> locations;
  final VisualStyle? visualStyle;

  const CharacterBible({
    required this.characters,
    required this.locations,
    this.visualStyle,
  });

  factory CharacterBible.fromJson(dynamic raw) {
    try {
      final json = Map<String, dynamic>.from(raw as Map);
      return CharacterBible(
        characters: (json['characters'] as List? ?? [])
            .map((e) => CharacterBibleEntry.fromJson(e))
            .toList(),
        locations: (json['locations'] as List? ?? [])
            .map((e) => LocationEntry.fromJson(e))
            .toList(),
        visualStyle: json['visual_style'] != null
            ? VisualStyle.fromJson(json['visual_style'])
            : null,
      );
    } catch (_) {
      return const CharacterBible(characters: [], locations: []);
    }
  }
}

// ─── Scene Item ───────────────────────────────────────────────────────────────
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

  factory SceneItem.fromJson(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    return SceneItem(
      sceneNumber: json['scene_number'] ?? 0,
      timeStart: json['time_start']?.toString() ?? '',
      timeEnd: json['time_end']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      visualDescription: json['visual_description']?.toString() ?? '',
      narrationText: json['narration_text']?.toString() ?? '',
      mood: json['mood']?.toString() ?? '',
      bRollSuggestion: json['b_roll_suggestion']?.toString(),
      transition: json['transition']?.toString(),
    );
  }
}

// ─── Video Prompt Item ────────────────────────────────────────────────────────
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

  factory VideoPromptItem.fromJson(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    return VideoPromptItem(
      sceneNumber: json['scene_number'] ?? 0,
      prompt: json['prompt']?.toString() ?? '',
      negativePrompt: json['negative_prompt']?.toString(),
      cameraWork: json['camera_work']?.toString(),
      lighting: json['lighting']?.toString(),
      styleTags: _safeStringList(json['style_tags']),
      duration: json['duration']?.toString() ?? '5s',
    );
  }
}

// ─── Image Prompt Item ────────────────────────────────────────────────────────
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

  factory ImagePromptItem.fromJson(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    return ImagePromptItem(
      sceneNumber: json['scene_number'] ?? 0,
      midjourney: json['midjourney']?.toString(),
      stableDiffusion: json['stable_diffusion']?.toString(),
      leonardo: json['leonardo']?.toString(),
      dallE: json['dall_e']?.toString(),
      purpose: json['purpose']?.toString(),
      styleReference: json['style_reference']?.toString(),
    );
  }

  // Returns true only if at least one prompt has real content
  bool get hasContent =>
      (midjourney?.isNotEmpty ?? false) ||
      (stableDiffusion?.isNotEmpty ?? false) ||
      (leonardo?.isNotEmpty ?? false) ||
      (dallE?.isNotEmpty ?? false);
}

// ─── YouTube SEO ──────────────────────────────────────────────────────────────
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

  factory YouTubeSeo.fromJson(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    return YouTubeSeo(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      tags: _safeStringList(json['tags']),
      category: json['category']?.toString(),
    );
  }
}

// ─── Hashtag Set ──────────────────────────────────────────────────────────────
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
        primary: _safeStringList(json),
        secondary: [],
        niche: [],
        trending: [],
      );
    }
    final map = Map<String, dynamic>.from(json as Map);
    return HashtagSet(
      primary: _safeStringList(map['primary']),
      secondary: _safeStringList(map['secondary']),
      niche: _safeStringList(map['niche']),
      trending: _safeStringList(map['trending']),
    );
  }

  List<String> get all => [...primary, ...secondary, ...niche, ...trending];
}

// ─── Video Titles ─────────────────────────────────────────────────────────────
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

  factory VideoTitles.fromJson(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    return VideoTitles(
      youtube: json['youtube']?.toString() ?? '',
      tiktok: json['tiktok']?.toString() ?? '',
      instagram: json['instagram']?.toString() ?? '',
      facebook: json['facebook']?.toString() ?? '',
      shorts: json['shorts']?.toString() ?? '',
      primary: json['primary']?.toString() ??
          json['youtube']?.toString() ?? '',
    );
  }
}

// ─── Production Notes ─────────────────────────────────────────────────────────
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

  factory ProductionNotes.fromJson(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    return ProductionNotes(
      totalScenesNeeded: json['total_scenes_needed'] ?? 0,
      detailedScenesProvided: json['detailed_scenes_provided'] ?? 0,
      clipDurationSeconds: json['clip_duration_seconds'] ?? 5,
      proTips: _safeStringList(json['pro_tips']),
      recommendedEditingTool:
          json['recommended_editing_tool']?.toString(),
    );
  }
}

// ─── Video Result ─────────────────────────────────────────────────────────────
class VideoResult {
  final CharacterBible? characterBible; // ← Added
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
    this.characterBible,
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

  factory VideoResult.fromJson(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);

    // ── Parse image prompts safely — filter out empty ones ──────────────────
    final rawImagePrompts = json['image_prompts'] as List? ?? [];
    final imagePrompts = rawImagePrompts
        .map((e) => ImagePromptItem.fromJson(e))
        .where((e) => e.hasContent) // Only keep prompts with real content
        .toList();

    return VideoResult(
      characterBible: json['character_bible'] != null
          ? CharacterBible.fromJson(json['character_bible'])
          : null,
      titles: VideoTitles.fromJson(json['titles'] ?? {}),
      viralHook: json['viral_hook']?.toString() ?? '',
      fullScript: json['full_script']?.toString() ?? '',
      sceneBreakdown: (json['scene_breakdown'] as List? ?? [])
          .map((e) => SceneItem.fromJson(e))
          .toList(),
      videoPrompts: (json['video_prompts'] as List? ?? [])
          .map((e) => VideoPromptItem.fromJson(e))
          .toList(),
      imagePrompts: imagePrompts,
      voiceOverScript: json['voice_over_script']?.toString(),
      youtubeSeo: YouTubeSeo.fromJson(json['youtube_seo'] ?? {}),
      hashtags: HashtagSet.fromJson(json['hashtags'] ?? {}),
      thumbnailPrompt: json['thumbnail_prompt']?.toString() ?? '',
      subtitleScript: json['subtitle_script']?.toString() ?? '',
      productionNotes: json['production_notes'] != null
          ? ProductionNotes.fromJson(json['production_notes'])
          : null,
    );
  }
}

// ─── Project Model ────────────────────────────────────────────────────────────
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

  factory ProjectModel.fromJson(dynamic raw) {
    final json = Map<String, dynamic>.from(raw as Map);
    return ProjectModel(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      idea: json['idea']?.toString() ?? '',
      contentType: json['content_type']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      durationMinutes: json['duration_minutes'] ?? 5,
      generator: json['generator']?.toString() ?? '',
      generateImagePrompts: json['generate_image_prompts'] ?? false,
      generateVoiceOver: json['generate_voice_over'] ?? false,
      status: json['status']?.toString() ?? 'pending',
      totalScenes: json['total_scenes'] ?? 0,
      clipDurationSeconds: json['clip_duration_seconds'] ?? 5,
      aiProviderUsed: json['ai_provider_used']?.toString(),
      createdAt: json['created_at']?.toString(),
      result: json['result'] != null
          ? VideoResult.fromJson(json['result'])
          : null,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isProcessing => status == 'processing';
}

// ─── Helper ───────────────────────────────────────────────────────────────────
List<String> _safeStringList(dynamic val) {
  if (val == null) return [];
  if (val is List) return val.map((e) => e?.toString() ?? '').toList();
  return [];
}
