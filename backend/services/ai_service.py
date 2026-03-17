"""
PromptReel AI — Multi-Provider AI Service
==========================================
Provider roster and plan-based routing:

  STUDIO  → GPT-4o → Claude 3.5 Sonnet → Grok-2 → Gemini Pro → Mistral Large → DeepSeek
  CREATOR → GPT-4o-mini → Grok-2 → Gemini Pro → Mistral Large → Claude Sonnet → DeepSeek → Groq
  FREE    → Gemini Flash → Groq Llama 3.3 → DeepSeek-V3 → Together Qwen → OpenRouter → GPT-4o-mini

Smart split generation (handles 1min → 20min videos, never hits token limits):
  PART META  → character_bible, titles, SEO, hashtags, voice_over, production_notes
  PART IMG-N → image_prompts in batches of 10 scenes each
  PART SC-N  → scene_breakdown in batches of 10 scenes each
  PART VP-N  → video_prompts in batches of 10 scenes each (uses scene context)
  PART LAST  → full_script
  MERGE      → combine all parts into one complete response

  Example — 5 min / Kling = 30 scenes → 10 API calls total
  Example — 20 min / Kling = 120 scenes → 37 API calls total (all safe)
"""
import json
import logging
import re
from config import settings

logger = logging.getLogger(__name__)

# ─── Clip Duration Config ─────────────────────────────────────────────────────
CLIP_DURATIONS = {
    "Runway": 5, "Pika": 3, "Kling": 10,
    "Sora": 15, "Luma": 5, "Haiper": 4, "Other": 5,
}
DURATION_SECONDS = {1: 60, 3: 180, 5: 300, 10: 600, 20: 1200}

# Scenes per batch — keeps every API call safely under 8000 tokens for Groq
BATCH_SIZE = 10


def calculate_scenes(duration_minutes: int, generator: str) -> int:
    return DURATION_SECONDS.get(duration_minutes, 300) // CLIP_DURATIONS.get(generator, 5)


def get_clip_duration(generator: str) -> int:
    return CLIP_DURATIONS.get(generator, 5)


def _make_batches(total: int, batch_size: int = BATCH_SIZE) -> list[tuple[int, int]]:
    """Return list of (start, end) 1-indexed scene range tuples."""
    batches = []
    for i in range(0, total, batch_size):
        start = i + 1
        end   = min(i + batch_size, total)
        batches.append((start, end))
    return batches


# ─── Provider Callers ─────────────────────────────────────────────────────────

async def call_openai(prompt: str, model: str) -> str:
    from openai import AsyncOpenAI
    client = AsyncOpenAI(api_key=settings.OPENAI_API_KEY)
    resp = await client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "You are PromptReel AI. Respond ONLY with valid JSON. No markdown, no explanation."},
            {"role": "user", "content": prompt},
        ],
        max_tokens=16000,
        temperature=0.82,
        response_format={"type": "json_object"},
    )
    return resp.choices[0].message.content


async def call_anthropic(prompt: str, model: str) -> str:
    import anthropic
    client = anthropic.AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
    msg = await client.messages.create(
        model=model,
        max_tokens=16000,
        system="You are PromptReel AI. Respond ONLY with valid JSON. No markdown, no code fences, no preamble.",
        messages=[{"role": "user", "content": prompt}],
    )
    return msg.content[0].text


async def call_gemini(prompt: str, model: str) -> str:
    import google.generativeai as genai
    genai.configure(api_key=settings.GEMINI_API_KEY)
    gm = genai.GenerativeModel(
        model_name=model,
        generation_config={
            "temperature": 0.82,
            "max_output_tokens": 16000,
            "response_mime_type": "application/json",
        },
        system_instruction="You are PromptReel AI. Respond ONLY with valid JSON.",
    )
    resp = await gm.generate_content_async(prompt)
    return resp.text


async def call_grok(prompt: str, model: str) -> str:
    from openai import AsyncOpenAI
    client = AsyncOpenAI(api_key=settings.GROK_API_KEY, base_url="https://api.x.ai/v1")
    resp = await client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "You are PromptReel AI. Respond ONLY with valid JSON. No markdown."},
            {"role": "user", "content": prompt},
        ],
        max_tokens=16000,
        temperature=0.82,
        response_format={"type": "json_object"},
    )
    return resp.choices[0].message.content


async def call_mistral(prompt: str, model: str) -> str:
    import httpx
    async with httpx.AsyncClient(timeout=120) as client:
        resp = await client.post(
            "https://api.mistral.ai/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {settings.MISTRAL_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": model,
                "messages": [
                    {"role": "system", "content": "You are PromptReel AI. Respond ONLY with valid JSON. No markdown."},
                    {"role": "user", "content": prompt},
                ],
                "max_tokens": 16000,
                "temperature": 0.82,
                "response_format": {"type": "json_object"},
            },
        )
        resp.raise_for_status()
        return resp.json()["choices"][0]["message"]["content"]


async def call_deepseek(prompt: str, model: str) -> str:
    from openai import AsyncOpenAI
    client = AsyncOpenAI(
        api_key=settings.DEEPSEEK_API_KEY,
        base_url="https://api.deepseek.com",
    )
    resp = await client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "You are PromptReel AI. Respond ONLY with valid JSON. No markdown."},
            {"role": "user", "content": prompt},
        ],
        max_tokens=16000,
        temperature=0.82,
        response_format={"type": "json_object"},
    )
    return resp.choices[0].message.content


async def call_groq(prompt: str, model: str) -> str:
    from openai import AsyncOpenAI
    client = AsyncOpenAI(
        api_key=settings.GROQ_API_KEY,
        base_url="https://api.groq.com/openai/v1",
    )
    resp = await client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": "You are PromptReel AI. Respond ONLY with valid JSON. No markdown."},
            {"role": "user", "content": prompt},
        ],
        max_tokens=8000,
        temperature=0.82,
        response_format={"type": "json_object"},
    )
    return resp.choices[0].message.content


async def call_together(prompt: str, model: str) -> str:
    import httpx
    async with httpx.AsyncClient(timeout=120) as client:
        resp = await client.post(
            "https://api.together.xyz/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {settings.TOGETHER_API_KEY}",
                "Content-Type": "application/json",
            },
            json={
                "model": model,
                "messages": [
                    {"role": "system", "content": "You are PromptReel AI. Respond ONLY with valid JSON. No markdown, no preamble, no code fences."},
                    {"role": "user", "content": prompt},
                ],
                "max_tokens": 16000,
                "temperature": 0.82,
            },
        )
        resp.raise_for_status()
        return resp.json()["choices"][0]["message"]["content"]


async def call_openrouter(prompt: str, model: str) -> str:
    import httpx
    async with httpx.AsyncClient(timeout=120) as client:
        resp = await client.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://promptreel.ai",
                "X-Title": "PromptReel AI",
            },
            json={
                "model": model,
                "messages": [
                    {"role": "system", "content": "You are PromptReel AI. Respond ONLY with valid JSON. No markdown."},
                    {"role": "user", "content": prompt},
                ],
                "max_tokens": 16000,
                "temperature": 0.82,
                "response_format": {"type": "json_object"},
            },
        )
        resp.raise_for_status()
        return resp.json()["choices"][0]["message"]["content"]


# ─── Plan → Provider Chain ────────────────────────────────────────────────────
def get_provider_chain(user_plan: str) -> list[tuple[str, any, str]]:
    s = settings
    chains: dict[str, list[tuple]] = {
        "studio": [
            ("openai-gpt4o",        call_openai,    s.OPENAI_MODEL_STUDIO,    s.OPENAI_API_KEY),
            ("anthropic-sonnet3.5", call_anthropic, s.ANTHROPIC_MODEL_STUDIO, s.ANTHROPIC_API_KEY),
            ("grok-2",              call_grok,      s.GROK_MODEL_CREATOR,     s.GROK_API_KEY),
            ("gemini-pro",          call_gemini,    s.GEMINI_MODEL_CREATOR,   s.GEMINI_API_KEY),
            ("mistral-large",       call_mistral,   s.MISTRAL_MODEL_CREATOR,  s.MISTRAL_API_KEY),
            ("deepseek-v3",         call_deepseek,  s.DEEPSEEK_MODEL_FREE,    s.DEEPSEEK_API_KEY),
            ("groq-llama3.3-70b",   call_groq,      s.GROQ_MODEL_FREE,        s.GROQ_API_KEY),
            ("together-qwen2.5",    call_together,  s.TOGETHER_MODEL_FREE,    s.TOGETHER_API_KEY),
        ],
        "creator": [
            ("openai-gpt4o-mini",   call_openai,    s.OPENAI_MODEL_CREATOR,   s.OPENAI_API_KEY),
            ("grok-2",              call_grok,      s.GROK_MODEL_CREATOR,     s.GROK_API_KEY),
            ("gemini-pro",          call_gemini,    s.GEMINI_MODEL_CREATOR,   s.GEMINI_API_KEY),
            ("mistral-large",       call_mistral,   s.MISTRAL_MODEL_CREATOR,  s.MISTRAL_API_KEY),
            ("anthropic-sonnet3.5", call_anthropic, s.ANTHROPIC_MODEL_STUDIO, s.ANTHROPIC_API_KEY),
            ("deepseek-v3",         call_deepseek,  s.DEEPSEEK_MODEL_FREE,    s.DEEPSEEK_API_KEY),
            ("groq-llama3.3-70b",   call_groq,      s.GROQ_MODEL_FREE,        s.GROQ_API_KEY),
            ("together-qwen2.5",    call_together,  s.TOGETHER_MODEL_FREE,    s.TOGETHER_API_KEY),
        ],
        "free": [
            ("gemini-flash",        call_gemini,    s.GEMINI_MODEL_FREE,      s.GEMINI_API_KEY),
            ("groq-llama3.3-70b",   call_groq,      s.GROQ_MODEL_FREE,        s.GROQ_API_KEY),
            ("deepseek-v3",         call_deepseek,  s.DEEPSEEK_MODEL_FREE,    s.DEEPSEEK_API_KEY),
            ("together-qwen2.5",    call_together,  s.TOGETHER_MODEL_FREE,    s.TOGETHER_API_KEY),
            ("openrouter-llama",    call_openrouter,s.OPENROUTER_MODEL_FREE,  s.OPENROUTER_API_KEY),
            ("openai-gpt4o-mini",   call_openai,    s.OPENAI_MODEL_CREATOR,   s.OPENAI_API_KEY),
            ("mistral-large",       call_mistral,   s.MISTRAL_MODEL_CREATOR,  s.MISTRAL_API_KEY),
        ],
    }
    raw = chains.get(user_plan, chains["free"])
    return [(label, fn, model) for label, fn, model, key in raw if key]


# ─── PART META: character_bible + titles + SEO + voice_over ──────────────────
def _build_meta_prompt(
    idea: str,
    content_type: str,
    platform: str,
    duration_minutes: int,
    generator: str,
    clip_duration: int,
    total_scenes: int,
    generate_voice_over: bool,
    content_type_options: dict,
) -> str:
    detailed_scenes = min(total_scenes, 60)
    tone_map = {
        "Educational":  "authoritative, clear — like National Geographic",
        "Narration":    "warm, engaging, storytelling-focused",
        "Commentary":   "opinionated, conversational, entertaining",
        "Documentary":  "cinematic, serious, compelling",
        "Storytelling": "narrative-driven, emotional, immersive",
        "Comedy":       "witty, fast-paced, humorous",
        "Horror":       "eerie, suspenseful, atmospheric",
        "Motivational": "inspiring, energetic, empowering",
        "News":         "objective, authoritative, concise",
        "Realistic":    "grounded, factual, authentic",
    }
    platform_tips = {
        "YouTube":        "optimize for watch time, strong CTAs",
        "TikTok":         "hook in first 3 seconds, fast cuts",
        "Instagram":      "aesthetic visuals, story-driven",
        "Facebook":       "shareable, emotional, community-focused",
        "YouTube Shorts": "punchy 60-second hook, vertical format",
        "X (Twitter)":    "concise, thought-provoking",
    }
    content_options_block = ""
    if content_type_options:
        opts = "\n".join([f"  {k.replace('_',' ').upper()}: {v}" for k, v in content_type_options.items()])
        content_options_block = f"\nCONTENT SETTINGS:\n{opts}"

    vo = (
        f"Write the REAL complete {duration_minutes}-minute timed voice-over. "
        f"Format: [MM:SS] narration text every 10 seconds from [00:00] to [{duration_minutes:02d}:00]. "
        f"Min {duration_minutes * 130} words."
        if generate_voice_over else "Not requested"
    )

    return f"""You are PromptReel AI. Generate the META section ONLY — no scene lists.

IDEA: {idea}
TYPE: {content_type} — {tone_map.get(content_type, "engaging")}
PLATFORM: {platform} — {platform_tips.get(platform, "")}
DURATION: {duration_minutes} min | GENERATOR: {generator} ({clip_duration}s clips)
TOTAL SCENES: {total_scenes} | DETAILED SCENES: {detailed_scenes}
VOICE-OVER: {"YES" if generate_voice_over else "NO"}{content_options_block}

Define characters, locations, visual style, and all meta fields.
Do NOT generate scene_breakdown, video_prompts, or image_prompts here.
Return ONLY valid JSON. Pure JSON, no markdown.

{{
  "character_bible": {{
    "characters": [{{
      "id": "CHARACTER_ID e.g. MAIN_CAT",
      "name": "display name",
      "type": "species/type",
      "appearance": {{
        "size": "exact size and build",
        "colors": "exact colors — very specific, no vague terms",
        "markings": "unique markings e.g. white star on chest",
        "eyes": "exact eye color and shape",
        "distinctive_features": "anything unique that never changes",
        "accessories": "collar, clothing, hat, etc"
      }},
      "movement_style": "how they move",
      "personality_visual": "visual personality cues"
    }}],
    "locations": [{{
      "id": "LOCATION_ID",
      "name": "location name",
      "description": "exact visual details locked forever",
      "lighting": "exact lighting and time of day",
      "atmosphere": "mood and atmosphere"
    }}],
    "visual_style": {{
      "style": "photorealistic/animated/cartoon/cinematic",
      "color_grading": "warm/cool/vibrant/desaturated",
      "lighting_mood": "golden hour/dramatic/neon/natural",
      "consistency_seed": "20-word style description for every scene"
    }}
  }},
  "titles": {{
    "youtube": "60-char high-CTR title",
    "tiktok": "TikTok hook with 1-2 emojis",
    "instagram": "aspirational caption title",
    "facebook": "curiosity/emotional trigger",
    "shorts": "punchy title under 40 chars",
    "primary": "best cross-platform title"
  }},
  "viral_hook": "2-3 sentence shocking opener that makes viewer unable to leave.",
  "thumbnail_prompt": "Real thumbnail using ACTUAL locked character appearance: exact character description, bold yellow 3-word hook text overlay, high contrast cinematic background, rule of thirds composition, viral YouTube style. Min 50 words.",
  "youtube_seo": {{
    "title": "SEO title keyword at start",
    "description": "Full 1500+ char: hook, emoji bullets, timestamps, CTA, keywords",
    "tags": ["tag1","tag2","tag3","tag4","tag5","tag6","tag7","tag8","tag9","tag10","tag11","tag12","tag13","tag14","tag15","tag16","tag17","tag18","tag19","tag20"],
    "category": "most appropriate YouTube category"
  }},
  "hashtags": {{
    "primary": ["#Tag1","#Tag2","#Tag3","#Tag4","#Tag5"],
    "secondary": ["#Tag6","#Tag7","#Tag8","#Tag9","#Tag10","#Tag11","#Tag12","#Tag13","#Tag14","#Tag15"],
    "niche": ["#Tag16","#Tag17","#Tag18","#Tag19","#Tag20","#Tag21","#Tag22","#Tag23","#Tag24","#Tag25"],
    "trending": ["#Tag26","#Tag27","#Tag28","#Tag29","#Tag30"]
  }},
  "subtitle_script": "1\\n00:00:00,000 --> 00:00:{clip_duration:02d},000\\nOpening narration\\n\\n2\\n00:00:{clip_duration:02d},000 --> 00:00:{clip_duration*2:02d},000\\nContinuing narration",
  "voice_over_script": "{vo}",
  "production_notes": {{
    "total_scenes_needed": {total_scenes},
    "detailed_scenes_provided": {detailed_scenes},
    "clip_duration_seconds": {clip_duration},
    "estimated_word_count": {duration_minutes * 130},
    "recommended_editing_tool": "CapCut or DaVinci Resolve",
    "pro_tips": [
      "Character consistency tip for {generator}",
      "Platform tip for {platform}",
      "Retention tip",
      "Monetization tip"
    ]
  }}
}}

Pure JSON only. Fill every field with real content."""


# ─── IMAGE PROMPTS BATCH ──────────────────────────────────────────────────────
def _build_image_prompts_batch(
    idea: str,
    content_type: str,
    generator: str,
    clip_duration: int,
    total_scenes: int,
    scene_start: int,
    scene_end: int,
    character_bible_json: str,
) -> str:
    batch_count = scene_end - scene_start + 1
    return f"""You are PromptReel AI. Generate IMAGE PROMPTS for scenes {scene_start} to {scene_end}.

IDEA: {idea} | TYPE: {content_type} | GENERATOR: {generator} | TOTAL SCENES: {total_scenes}
TASK: Generate ONLY image_prompts for scenes {scene_start} through {scene_end} ({batch_count} scenes)

LOCKED CHARACTER BIBLE — paste EXACT appearance into every prompt:
{character_bible_json}

RULES:
- Generate EXACTLY {batch_count} entries (scene {scene_start} to {scene_end})
- scene_number must be sequential: {scene_start}, {scene_start+1} ... {scene_end}
- Each scene reflects THAT scene's specific action and environment
- Character locked appearance = IDENTICAL in ALL prompts
- Only action, camera angle, setting changes between scenes
- Write REAL copy-paste prompts — no placeholder brackets in output
- Example correct output: "jet black British Shorthair cat, green almond eyes,
  red collar with silver bell, white paws, sitting alert at top of wooden stairs,
  warm hallway lamp glow, photorealistic --ar 16:9 --v 6.1 --style raw --q 2"

{{
  "image_prompts": [
    {{
      "scene_number": {scene_start},
      "midjourney": "REAL Midjourney prompt: [exact locked character appearance], [scene {scene_start} action], [scene {scene_start} environment], [lighting], photorealistic, ultra-detailed --ar 16:9 --v 6.1 --style raw --q 2",
      "stable_diffusion": "REAL SD prompt: [exact locked character appearance], [scene {scene_start} action], [environment], masterpiece, best quality, ultra-detailed, photorealistic, 8K, cinematic lighting",
      "leonardo": "REAL Leonardo prompt: [exact locked character appearance], [scene {scene_start} action], [environment], highly detailed, cinematic, professional photography",
      "dall_e": "REAL DALL-E: A photorealistic image of [exact locked character appearance] [scene {scene_start} action] in [environment], [mood], [lighting]",
      "purpose": "establishing_shot"
    }}
  ]
}}

Generate ALL {batch_count} entries for scenes {scene_start} to {scene_end}.
Replace ALL brackets with real content. Pure JSON only."""


# ─── SCENE BREAKDOWN BATCH ───────────────────────────────────────────────────
def _build_scene_batch(
    idea: str,
    content_type: str,
    platform: str,
    duration_minutes: int,
    generator: str,
    clip_duration: int,
    total_scenes: int,
    scene_start: int,
    scene_end: int,
    character_bible_json: str,
    content_type_options: dict,
) -> str:
    batch_count = scene_end - scene_start + 1
    content_options_block = ""
    if content_type_options:
        opts = "\n".join([f"  {k.replace('_',' ').upper()}: {v}" for k, v in content_type_options.items()])
        content_options_block = f"\nCONTENT SETTINGS:\n{opts}"

    return f"""You are PromptReel AI. Generate SCENE BREAKDOWN for scenes {scene_start} to {scene_end}.

IDEA: {idea} | TYPE: {content_type} | PLATFORM: {platform} | DURATION: {duration_minutes} min
GENERATOR: {generator} ({clip_duration}s clips) | TOTAL SCENES: {total_scenes}
TASK: Generate ONLY scene_breakdown for scenes {scene_start} through {scene_end} ({batch_count} scenes){content_options_block}

LOCKED CHARACTER BIBLE — include FULL appearance in every visual_description:
{character_bible_json}

RULES:
- Generate EXACTLY {batch_count} scene_breakdown entries (scene {scene_start} to {scene_end})
- scene_number sequential: {scene_start}, {scene_start+1} ... {scene_end}
- Every visual_description MUST include CHARACTER_ID + full locked appearance
- Apply content settings to narrator voice, accent, pace
- Each scene continues the story logically from the previous
- Pure JSON only

{{
  "scene_breakdown": [
    {{
      "scene_number": {scene_start},
      "time_start": "{(scene_start-1)*clip_duration//60}:{((scene_start-1)*clip_duration)%60:02d}",
      "time_end": "{scene_start*clip_duration//60}:{(scene_start*clip_duration)%60:02d}",
      "title": "Evocative scene title",
      "visual_description": "CHARACTER_ID (exact locked appearance) — specific action for scene {scene_start}. Setting: LOCATION_ID (locked environment). Camera: angle and movement.",
      "narration_text": "Exact narrator words for this {clip_duration}s scene",
      "mood": "tense/mysterious/dramatic/inspiring/funny/etc",
      "b_roll_suggestion": "Supplementary footage idea",
      "transition": "cut/fade/zoom/whip-pan/dissolve"
    }}
  ]
}}

Generate ALL {batch_count} entries for scenes {scene_start} to {scene_end}. Pure JSON only."""


# ─── VIDEO PROMPTS BATCH ──────────────────────────────────────────────────────
def _build_video_prompts_batch(
    idea: str,
    content_type: str,
    generator: str,
    clip_duration: int,
    total_scenes: int,
    scene_start: int,
    scene_end: int,
    character_bible_json: str,
    scenes_context: list,
) -> str:
    batch_count = scene_end - scene_start + 1

    # Build scene context so video prompts match scene_breakdown exactly
    scene_context_str = ""
    if scenes_context:
        lines = []
        for sc in scenes_context:
            n  = sc.get("scene_number", "?")
            t  = sc.get("title", "")
            vd = sc.get("visual_description", "")[:150]
            lines.append(f"  Scene {n}: {t} — {vd}...")
        scene_context_str = "\nSCENE CONTEXT (your video_prompts MUST match these actions):\n" + "\n".join(lines)

    return f"""You are PromptReel AI. Generate VIDEO PROMPTS for scenes {scene_start} to {scene_end}.

IDEA: {idea} | TYPE: {content_type} | GENERATOR: {generator} ({clip_duration}s clips) | TOTAL SCENES: {total_scenes}
TASK: Generate ONLY video_prompts for scenes {scene_start} through {scene_end} ({batch_count} scenes){scene_context_str}

LOCKED CHARACTER BIBLE — paste FULL appearance at START of every prompt:
{character_bible_json}

RULES:
- Generate EXACTLY {batch_count} video_prompt entries (scene {scene_start} to {scene_end})
- scene_number sequential: {scene_start}, {scene_start+1} ... {scene_end}
- Every prompt MUST start with the character's COMPLETE locked appearance from bible
- Every prompt must MATCH that scene's action from the scene context above
- Character appearance = IDENTICAL in all prompts — only action/setting changes
- Pure JSON only

{{
  "video_prompts": [
    {{
      "scene_number": {scene_start},
      "prompt": "[Character FULL locked appearance] — [scene {scene_start} exact action from context], [locked environment], [camera movement], [locked lighting], [locked visual style], {generator} optimized, photorealistic, 4K, ultra-detailed, character consistency",
      "negative_prompt": "inconsistent character, different appearance, character change, blurry, text, watermark, low quality, distorted",
      "camera_work": "specific camera movement for scene {scene_start}",
      "lighting": "matches character_bible visual_style lighting_mood",
      "style_tags": ["consistent character", "cinematic", "photorealistic", "4K"],
      "duration": "{clip_duration}s"
    }}
  ]
}}

Generate ALL {batch_count} video_prompt entries for scenes {scene_start} to {scene_end}.
Each prompt must match its scene's action. Pure JSON only."""


# ─── FULL SCRIPT ──────────────────────────────────────────────────────────────
def _build_script_prompt(
    idea: str,
    content_type: str,
    platform: str,
    duration_minutes: int,
    total_scenes: int,
    clip_duration: int,
    character_bible_json: str,
    content_type_options: dict,
) -> str:
    detailed_scenes = min(total_scenes, 60)
    content_options_block = ""
    if content_type_options:
        opts = "\n".join([f"  {k.replace('_',' ').upper()}: {v}" for k, v in content_type_options.items()])
        content_options_block = f"\nCONTENT SETTINGS:\n{opts}"

    return f"""You are PromptReel AI. Write a complete video narration script.

IDEA: {idea} | TYPE: {content_type} | PLATFORM: {platform}
DURATION: {duration_minutes} min | TOTAL SCENES: {total_scenes} | CLIP: {clip_duration}s each{content_options_block}

CHARACTER BIBLE:
{character_bible_json}

Write a complete {duration_minutes}-minute narration script.
Mark each scene with [SCENE 1], [SCENE 2] ... [SCENE {detailed_scenes}].
Apply narrator voice, accent, and pace from content settings.
Reference characters by their locked IDs.
Minimum {duration_minutes * 130} words.

Return ONLY this JSON:
{{
  "full_script": "Complete {duration_minutes}-minute narration with [SCENE X] markers here..."
}}

Pure JSON only."""


def parse_json_response(raw: str) -> dict:
    cleaned = re.sub(r"```json\s*", "", raw)
    cleaned = re.sub(r"```\s*", "", cleaned).strip()
    start, end = cleaned.find("{"), cleaned.rfind("}") + 1
    if start != -1 and end > start:
        cleaned = cleaned[start:end]
    return json.loads(cleaned)


async def _call_with_chain(
    prompt: str,
    chain: list,
    label: str = "",
) -> tuple[dict, str]:
    """Try each provider in the chain until one succeeds."""
    last_error = None
    for name, caller, model in chain:
        try:
            logger.info(f"  → [{label}] {name} ({model})")
            raw    = await caller(prompt, model)
            result = parse_json_response(raw)
            logger.info(f"  ✅ [{label}] {name}")
            return result, name
        except json.JSONDecodeError as e:
            logger.warning(f"  ✗ [{label}] {name}: bad JSON — {e}")
            last_error = e
        except Exception as e:
            logger.warning(f"  ✗ [{label}] {name}: {type(e).__name__} — {e}")
            last_error = e
    raise RuntimeError(f"All providers failed [{label}]. Last: {last_error}")


# ─── Main Entry ───────────────────────────────────────────────────────────────
async def generate_video_plan(
    idea: str,
    content_type: str,
    platform: str,
    duration_minutes: int,
    generator: str,
    generate_image_prompts: bool,
    generate_voice_over: bool,
    user_plan: str = "free",
    content_type_options: dict = {},
) -> tuple[dict, str]:

    clip_duration   = get_clip_duration(generator)
    total_scenes    = calculate_scenes(duration_minutes, generator)
    detailed_scenes = min(total_scenes, 60)
    batches         = _make_batches(detailed_scenes, BATCH_SIZE)
    chain           = get_provider_chain(user_plan)

    if not chain:
        raise ValueError(
            "No AI API keys configured. Set at least one of: "
            "GEMINI_API_KEY, GROQ_API_KEY, DEEPSEEK_API_KEY, OPENAI_API_KEY, "
            "GROK_API_KEY, ANTHROPIC_API_KEY, MISTRAL_API_KEY, "
            "TOGETHER_API_KEY, OPENROUTER_API_KEY"
        )

    img_batches  = len(batches) if generate_image_prompts else 0
    total_calls  = 1 + img_batches + len(batches) + len(batches) + 1
    logger.info(
        f"[{user_plan.upper()}] Smart split | "
        f"Scenes: {total_scenes} | Batches: {len(batches)} | "
        f"Total API calls: {total_calls} | "
        f"Image prompts: {generate_image_prompts}"
    )

    all_providers: list[str] = []

    # ═══════════════════════════════════════════════════════════════════════════
    # PART META — character_bible, titles, SEO, hashtags, voice_over
    # ═══════════════════════════════════════════════════════════════════════════
    logger.info("━━━ [1/META] character_bible, titles, SEO, hashtags, voice_over...")
    meta_result, meta_prov = await _call_with_chain(
        _build_meta_prompt(
            idea=idea, content_type=content_type, platform=platform,
            duration_minutes=duration_minutes, generator=generator,
            clip_duration=clip_duration, total_scenes=total_scenes,
            generate_voice_over=generate_voice_over,
            content_type_options=content_type_options,
        ),
        chain, "META",
    )
    all_providers.append(meta_prov)
    logger.info(f"✅ META done via {meta_prov}")

    character_bible_json = json.dumps(
        meta_result.get("character_bible", {}),
        indent=2, ensure_ascii=False,
    )

    # ═══════════════════════════════════════════════════════════════════════════
    # IMAGE PROMPT BATCHES — 10 scenes per call
    # ═══════════════════════════════════════════════════════════════════════════
    all_image_prompts: list = []

    if generate_image_prompts:
        for i, (s_start, s_end) in enumerate(batches, 1):
            label = f"IMG {i}/{len(batches)}"
            logger.info(f"━━━ [{label}] image_prompts scenes {s_start}→{s_end}...")
            img_result, img_prov = await _call_with_chain(
                _build_image_prompts_batch(
                    idea=idea, content_type=content_type, generator=generator,
                    clip_duration=clip_duration, total_scenes=total_scenes,
                    scene_start=s_start, scene_end=s_end,
                    character_bible_json=character_bible_json,
                ),
                chain, label,
            )
            all_providers.append(img_prov)
            batch_imgs = img_result.get("image_prompts", [])
            all_image_prompts.extend(batch_imgs)
            logger.info(f"✅ [{label}] done via {img_prov} — {len(batch_imgs)} prompts")

    all_image_prompts.sort(key=lambda x: x.get("scene_number", 0))
    logger.info(f"📸 Total image prompts: {len(all_image_prompts)}")

    # ═══════════════════════════════════════════════════════════════════════════
    # SCENE BREAKDOWN BATCHES — 10 scenes per call
    # ═══════════════════════════════════════════════════════════════════════════
    all_scene_breakdown: list = []

    for i, (s_start, s_end) in enumerate(batches, 1):
        label = f"SCENE {i}/{len(batches)}"
        logger.info(f"━━━ [{label}] scene_breakdown scenes {s_start}→{s_end}...")
        scene_result, scene_prov = await _call_with_chain(
            _build_scene_batch(
                idea=idea, content_type=content_type, platform=platform,
                duration_minutes=duration_minutes, generator=generator,
                clip_duration=clip_duration, total_scenes=total_scenes,
                scene_start=s_start, scene_end=s_end,
                character_bible_json=character_bible_json,
                content_type_options=content_type_options,
            ),
            chain, label,
        )
        all_providers.append(scene_prov)
        batch_scenes = scene_result.get("scene_breakdown", [])
        all_scene_breakdown.extend(batch_scenes)
        logger.info(f"✅ [{label}] done via {scene_prov} — {len(batch_scenes)} scenes")

    all_scene_breakdown.sort(key=lambda x: x.get("scene_number", 0))
    logger.info(f"🎬 Total scenes: {len(all_scene_breakdown)}")

    # ═══════════════════════════════════════════════════════════════════════════
    # VIDEO PROMPT BATCHES — 10 scenes per call, uses scene context
    # ═══════════════════════════════════════════════════════════════════════════
    all_video_prompts: list = []

    for i, (s_start, s_end) in enumerate(batches, 1):
        label = f"VP {i}/{len(batches)}"
        logger.info(f"━━━ [{label}] video_prompts scenes {s_start}→{s_end}...")

        # Pass scene context so video prompts match scene_breakdown exactly
        scenes_ctx = [
            sc for sc in all_scene_breakdown
            if s_start <= sc.get("scene_number", 0) <= s_end
        ]

        vp_result, vp_prov = await _call_with_chain(
            _build_video_prompts_batch(
                idea=idea, content_type=content_type, generator=generator,
                clip_duration=clip_duration, total_scenes=total_scenes,
                scene_start=s_start, scene_end=s_end,
                character_bible_json=character_bible_json,
                scenes_context=scenes_ctx,
            ),
            chain, label,
        )
        all_providers.append(vp_prov)
        batch_vps = vp_result.get("video_prompts", [])
        all_video_prompts.extend(batch_vps)
        logger.info(f"✅ [{label}] done via {vp_prov} — {len(batch_vps)} prompts")

    all_video_prompts.sort(key=lambda x: x.get("scene_number", 0))
    logger.info(f"🎥 Total video prompts: {len(all_video_prompts)}")

    # ═══════════════════════════════════════════════════════════════════════════
    # FULL SCRIPT — single call
    # ═══════════════════════════════════════════════════════════════════════════
    logger.info("━━━ [SCRIPT] full_script...")
    script_result, script_prov = await _call_with_chain(
        _build_script_prompt(
            idea=idea, content_type=content_type, platform=platform,
            duration_minutes=duration_minutes, total_scenes=total_scenes,
            clip_duration=clip_duration,
            character_bible_json=character_bible_json,
            content_type_options=content_type_options,
        ),
        chain, "SCRIPT",
    )
    all_providers.append(script_prov)
    logger.info(f"✅ SCRIPT done via {script_prov}")

    # ═══════════════════════════════════════════════════════════════════════════
    # MERGE — combine everything
    # ═══════════════════════════════════════════════════════════════════════════
    merged = {
        "character_bible":   meta_result.get("character_bible", {}),
        "titles":            meta_result.get("titles", {}),
        "viral_hook":        meta_result.get("viral_hook", ""),
        "thumbnail_prompt":  meta_result.get("thumbnail_prompt", ""),
        "youtube_seo":       meta_result.get("youtube_seo", {}),
        "hashtags":          meta_result.get("hashtags", {}),
        "subtitle_script":   meta_result.get("subtitle_script", ""),
        "voice_over_script": meta_result.get("voice_over_script", ""),
        "production_notes":  meta_result.get("production_notes", {}),
        "image_prompts":     all_image_prompts,
        "scene_breakdown":   all_scene_breakdown,
        "video_prompts":     all_video_prompts,
        "full_script":       script_result.get("full_script", ""),
    }

    logger.info(
        f"✅ GENERATION COMPLETE | "
        f"Scenes: {len(merged['scene_breakdown'])} | "
        f"Video prompts: {len(merged['video_prompts'])} | "
        f"Image prompts: {len(merged['image_prompts'])} | "
        f"API calls made: {len(all_providers)}"
    )

    # Deduplicate provider names for display
    seen = []
    for p in all_providers:
        if p not in seen:
            seen.append(p)
    return merged, "+".join(seen)
