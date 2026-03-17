"""
PromptReel AI — Multi-Provider AI Service
==========================================
Provider roster and plan-based routing:

  STUDIO  → GPT-4o → Claude 3.5 Sonnet → Grok-2 → Gemini Pro → Mistral Large → DeepSeek
  CREATOR → GPT-4o-mini → Grok-2 → Gemini Pro → Mistral Large → Claude Sonnet → DeepSeek → Groq
  FREE    → Gemini Flash → Groq Llama 3.3 → DeepSeek-V3 → Together Qwen → OpenRouter → GPT-4o-mini

Split generation strategy:
  CALL 1 → character_bible, titles, hook, SEO, hashtags, thumbnail,
            image_prompts (ALL scenes), voice_over, production_notes
  CALL 2 → full_script, scene_breakdown (ALL scenes), video_prompts (ALL scenes)
  CALL 3 → image_prompts continuation if needed (for long videos)
  MERGE  → combine all results into one complete response
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


def calculate_scenes(duration_minutes: int, generator: str) -> int:
    return DURATION_SECONDS.get(duration_minutes, 300) // CLIP_DURATIONS.get(generator, 5)


def get_clip_duration(generator: str) -> int:
    return CLIP_DURATIONS.get(generator, 5)


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


# ─── CALL 1 PROMPT: Short fields + image prompts ──────────────────────────────
def build_prompt_part1(
    idea: str,
    content_type: str,
    platform: str,
    duration_minutes: int,
    generator: str,
    clip_duration: int,
    total_scenes: int,
    generate_image_prompts: bool,
    generate_voice_over: bool,
    content_type_options: dict,
) -> str:
    detailed_scenes = min(total_scenes, 60)

    tone_map = {
        "Educational": "authoritative, clear",
        "Narration":   "warm, engaging, storytelling-focused",
        "Commentary":  "opinionated, conversational",
        "Documentary": "cinematic, serious, compelling",
        "Storytelling":"narrative-driven, emotional",
        "Comedy":      "witty, fast-paced, humorous",
        "Horror":      "eerie, suspenseful, atmospheric",
        "Motivational":"inspiring, energetic, empowering",
        "News":        "objective, authoritative, concise",
        "Realistic":   "grounded, factual, authentic",
    }

    content_options_block = ""
    if content_type_options:
        opts = "\n".join([
            f"  {k.replace('_',' ').upper()}: {v}"
            for k, v in content_type_options.items()
        ])
        content_options_block = f"\nCONTENT SETTINGS:\n{opts}"

    if generate_voice_over:
        vo_instruction = (
            f"Write the REAL complete {duration_minutes}-minute timed voice-over. "
            f"Format every line as [MM:SS] narration text. "
            f"Timestamp every 10 seconds from [00:00] to [{duration_minutes:02d}:00]. "
            f"Minimum {duration_minutes * 130} words."
        )
    else:
        vo_instruction = "Not requested"

    # ── Image prompts block with scene-accurate instructions ──────────────────
    if generate_image_prompts:
        img_block = f'''  "image_prompts": [
    {{
      "scene_number": 1,
      "midjourney": "Write the REAL Midjourney prompt for scene 1. Use the character's exact locked appearance from character_bible. Include scene 1 specific action and environment. End with --ar 16:9 --v 6.1 --style raw --q 2. Example output format: jet black cat, green eyes, blue collar, white paws, crouching near dark hole in wooden floor, warm living room lighting, cinematic --ar 16:9 --v 6.1 --style raw --q 2",
      "stable_diffusion": "Write the REAL SD prompt for scene 1. Use exact locked character appearance + scene 1 action + environment. Append: masterpiece, best quality, ultra-detailed, photorealistic, 8K, cinematic lighting",
      "leonardo": "Write the REAL Leonardo prompt for scene 1. Use exact locked character appearance + scene 1 action + environment. Append: highly detailed, cinematic, professional photography",
      "dall_e": "Write the REAL DALL-E sentence for scene 1. Format: A photorealistic image of [exact character appearance] [scene 1 action] in [scene 1 environment], [mood], [lighting]",
      "purpose": "establishing_shot"
    }},
    {{
      "scene_number": 2,
      "midjourney": "REAL Midjourney prompt for scene 2. SAME locked character appearance, DIFFERENT action/setting matching scene 2 story --ar 16:9 --v 6.1 --style raw --q 2",
      "stable_diffusion": "REAL SD prompt for scene 2 — same locked character, different scene 2 action/environment, masterpiece, best quality, photorealistic, 8K",
      "leonardo": "REAL Leonardo prompt for scene 2 — same locked character, different scene 2 action/environment, highly detailed, cinematic",
      "dall_e": "REAL DALL-E sentence for scene 2 — same locked character, different scene 2 action and environment",
      "purpose": "action_shot"
    }}
  ],

YOU MUST generate image_prompts for ALL {detailed_scenes} scenes numbered 1 through {detailed_scenes}.
Each scene_number must be unique and sequential: 1, 2, 3 ... {detailed_scenes}.
Each scene's prompts must reflect THAT scene's specific action and environment from the story.
The character locked appearance (colors, size, markings, accessories) must be IDENTICAL across all scenes.
Only the action, camera angle, and setting description changes between scenes.
Replace ALL example text above with REAL content — no placeholder brackets in final output.'''
    else:
        img_block = '  "image_prompts": [],'

    return f"""You are PromptReel AI. Generate PART 1 of a video production package.

IDEA: {idea}
TYPE: {content_type} — {tone_map.get(content_type, "engaging")}
PLATFORM: {platform} | DURATION: {duration_minutes} min | GENERATOR: {generator} ({clip_duration}s clips)
TOTAL SCENES: {total_scenes} | DETAILED SCENES: {detailed_scenes}
IMAGE PROMPTS: {"YES — generate for ALL " + str(detailed_scenes) + " scenes" if generate_image_prompts else "NO"}
VOICE-OVER: {"YES" if generate_voice_over else "NO"}{content_options_block}

STEP 1: Define ALL characters with exact locked appearance in character_bible.
STEP 2: Plan the story arc mentally — what happens in each of the {detailed_scenes} scenes.
STEP 3: Generate image_prompts for EVERY scene 1 through {detailed_scenes}, each one
        reflecting that scene's specific action while keeping character appearance LOCKED.
STEP 4: Return ONLY valid JSON. Pure JSON, no markdown.

CRITICAL RULES:
- Replace ALL example/placeholder text with REAL content
- image_prompts MUST have exactly {detailed_scenes} entries (scene 1 to {detailed_scenes})
- Each scene's image prompts must match that scene's story action
- Character appearance (species, colors, size, markings) = IDENTICAL in all scenes
- Only action, setting, camera angle changes between scenes

{{
  "character_bible": {{
    "characters": [{{
      "id": "CHARACTER_ID e.g. MAIN_CAT",
      "name": "display name",
      "type": "species/type",
      "appearance": {{
        "size": "exact size and build",
        "colors": "exact colors — be very specific",
        "markings": "unique markings e.g. white star on chest",
        "eyes": "eye color and shape",
        "distinctive_features": "unique features",
        "accessories": "collar, clothing, etc"
      }},
      "movement_style": "how they move",
      "personality_visual": "visual personality cues"
    }}],
    "locations": [{{
      "id": "LOCATION_ID",
      "name": "location name",
      "description": "exact visual details",
      "lighting": "lighting and time of day",
      "atmosphere": "mood"
    }}],
    "visual_style": {{
      "style": "photorealistic/animated/etc",
      "color_grading": "warm/cool/etc",
      "lighting_mood": "golden hour/dramatic/etc",
      "consistency_seed": "20-word style description"
    }}
  }},
  "titles": {{
    "youtube": "60-char CTR title",
    "tiktok": "hook with 1-2 emojis",
    "instagram": "aspirational title",
    "facebook": "emotional trigger",
    "shorts": "under 40 chars",
    "primary": "best cross-platform title"
  }},
  "viral_hook": "2-3 sentence shocking opener that makes viewer unable to leave.",
  "thumbnail_prompt": "Real thumbnail using ACTUAL locked character appearance with exact details, bold yellow 3-word hook text overlay, background scene, high contrast cinematic grade, rule of thirds composition. Min 50 words.",
  "youtube_seo": {{
    "title": "SEO title keyword at start",
    "description": "1500+ char: hook, emoji bullets, timestamps, CTA, keywords",
    "tags": ["tag1","tag2","tag3","tag4","tag5","tag6","tag7","tag8","tag9","tag10","tag11","tag12","tag13","tag14","tag15","tag16","tag17","tag18","tag19","tag20"],
    "category": "YouTube category"
  }},
  "hashtags": {{
    "primary": ["#Tag1","#Tag2","#Tag3","#Tag4","#Tag5"],
    "secondary": ["#Tag6","#Tag7","#Tag8","#Tag9","#Tag10","#Tag11","#Tag12","#Tag13","#Tag14","#Tag15"],
    "niche": ["#Tag16","#Tag17","#Tag18","#Tag19","#Tag20","#Tag21","#Tag22","#Tag23","#Tag24","#Tag25"],
    "trending": ["#Tag26","#Tag27","#Tag28","#Tag29","#Tag30"]
  }},
  "subtitle_script": "1\\n00:00:00,000 --> 00:00:{clip_duration:02d},000\\nOpening narration line\\n\\n2\\n00:00:{clip_duration:02d},000 --> 00:00:{clip_duration*2:02d},000\\nSecond narration line",
  "voice_over_script": "{vo_instruction}",
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
  }},
{img_block}
}}

Generate image_prompts for ALL {detailed_scenes} scenes. Pure JSON only. No placeholders in output."""


# ─── CALL 2 PROMPT: Long lists ────────────────────────────────────────────────
def build_prompt_part2(
    idea: str,
    content_type: str,
    platform: str,
    duration_minutes: int,
    generator: str,
    clip_duration: int,
    total_scenes: int,
    character_bible_json: str,
    content_type_options: dict,
) -> str:
    detailed_scenes = min(total_scenes, 60)

    content_options_block = ""
    if content_type_options:
        opts = "\n".join([
            f"  {k.replace('_',' ').upper()}: {v}"
            for k, v in content_type_options.items()
        ])
        content_options_block = f"\nCONTENT SETTINGS (apply to all output):\n{opts}"

    return f"""You are PromptReel AI. Generate PART 2 of a video production package.

IDEA: {idea}
TYPE: {content_type} | PLATFORM: {platform} | DURATION: {duration_minutes} min
GENERATOR: {generator} ({clip_duration}s clips) | TOTAL SCENES: {total_scenes}{content_options_block}

LOCKED CHARACTER BIBLE — use EXACTLY in every scene and prompt:
{character_bible_json}

CRITICAL RULES:
- Every scene visual_description MUST include the character ID + FULL locked appearance
- Every video_prompt MUST start with the character's complete locked appearance
- scene_breakdown and video_prompts must have matching scene_numbers 1 → {detailed_scenes}
- scene_breakdown and video_prompts must tell the SAME story — each video_prompt
  must visually represent exactly what scene_breakdown describes for that scene
- Apply content settings to narrator voice, accent, pace, style throughout
- Generate ALL {detailed_scenes} scene_breakdown entries
- Generate ALL {detailed_scenes} video_prompts
- Pure JSON only — no markdown

{{
  "full_script": "Complete {duration_minutes}-minute narration with [SCENE X] markers. Min {duration_minutes * 130} words. Match narrator voice/accent from content settings. Reference characters by their locked IDs throughout.",
  "scene_breakdown": [
    {{
      "scene_number": 1,
      "time_start": "0:00",
      "time_end": "0:{clip_duration:02d}",
      "title": "Evocative scene title",
      "visual_description": "CHARACTER_ID (exact locked appearance) — specific action in this scene. Setting: LOCATION_ID (locked environment details). Camera: specific angle and movement.",
      "narration_text": "Exact narrator words for this specific {clip_duration}s scene",
      "mood": "tense/mysterious/dramatic/inspiring/etc",
      "b_roll_suggestion": "Supplementary footage idea",
      "transition": "cut/fade/zoom/whip-pan"
    }}
  ],
  "video_prompts": [
    {{
      "scene_number": 1,
      "prompt": "[Character FULL locked appearance from character_bible] — [exact action from scene 1 scene_breakdown], [locked environment from scene 1], [camera movement], [locked lighting mood], [locked visual style], {generator} optimized, photorealistic, 4K, ultra-detailed, character consistency",
      "negative_prompt": "inconsistent character, different appearance, character change, blurry, text, watermark, low quality, distorted",
      "camera_work": "specific camera movement matching scene 1",
      "lighting": "matches character_bible visual_style lighting_mood",
      "style_tags": ["consistent character", "character reference", "cinematic", "photorealistic", "4K"],
      "duration": "{clip_duration}s"
    }}
  ]
}}

IMPORTANT: scene_breakdown scene {'{'}scene_number{'}'} and video_prompts scene {'{'}scene_number{'}'} 
must describe the SAME action and environment — they must match perfectly.
Generate ALL {detailed_scenes} entries for both arrays. Pure JSON only."""


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
    label_prefix: str = "",
) -> tuple[dict, str]:
    """Try each provider in chain until one succeeds."""
    last_error = None
    for label, caller, model in chain:
        try:
            logger.info(f"  → {label_prefix}{label} ({model})")
            raw = await caller(prompt, model)
            result = parse_json_response(raw)
            logger.info(f"  ✅ {label_prefix}{label}")
            return result, label
        except json.JSONDecodeError as e:
            logger.warning(f"  ✗ {label}: bad JSON — {e}")
            last_error = e
        except Exception as e:
            logger.warning(f"  ✗ {label}: {type(e).__name__} — {e}")
            last_error = e
    raise RuntimeError(f"All providers failed. Last error: {last_error}")


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
    clip_duration = get_clip_duration(generator)
    total_scenes  = calculate_scenes(duration_minutes, generator)
    chain = get_provider_chain(user_plan)

    if not chain:
        raise ValueError(
            "No AI API keys configured. Set at least one of: "
            "GEMINI_API_KEY, GROQ_API_KEY, DEEPSEEK_API_KEY, OPENAI_API_KEY, "
            "GROK_API_KEY, ANTHROPIC_API_KEY, MISTRAL_API_KEY, "
            "TOGETHER_API_KEY, OPENROUTER_API_KEY"
        )

    logger.info(
        f"[{user_plan.upper()}] Split generation. "
        f"Chain: {[p[0] for p in chain]} | "
        f"Scenes: {total_scenes} | "
        f"Image prompts: {generate_image_prompts}"
    )

    # ── CALL 1: Short fields + image prompts ──────────────────────────────────
    logger.info("📋 PART 1: character_bible, titles, SEO, hashtags, image_prompts...")
    prompt1 = build_prompt_part1(
        idea=idea,
        content_type=content_type,
        platform=platform,
        duration_minutes=duration_minutes,
        generator=generator,
        clip_duration=clip_duration,
        total_scenes=total_scenes,
        generate_image_prompts=generate_image_prompts,
        generate_voice_over=generate_voice_over,
        content_type_options=content_type_options,
    )

    part1_result, provider1 = await _call_with_chain(prompt1, chain, "P1-")

    # Log how many image prompts were generated
    img_count = len(part1_result.get("image_prompts", []))
    logger.info(f"✅ Part 1 done via {provider1} — {img_count} image prompts generated")

    # Extract character_bible JSON to pass into Part 2
    character_bible_json = json.dumps(
        part1_result.get("character_bible", {}),
        indent=2,
        ensure_ascii=False,
    )

    # ── CALL 2: Long lists ────────────────────────────────────────────────────
    logger.info("🎬 PART 2: full_script, scene_breakdown, video_prompts...")
    prompt2 = build_prompt_part2(
        idea=idea,
        content_type=content_type,
        platform=platform,
        duration_minutes=duration_minutes,
        generator=generator,
        clip_duration=clip_duration,
        total_scenes=total_scenes,
        character_bible_json=character_bible_json,
        content_type_options=content_type_options,
    )

    part2_result, provider2 = await _call_with_chain(prompt2, chain, "P2-")

    scene_count = len(part2_result.get("scene_breakdown", []))
    video_count = len(part2_result.get("video_prompts", []))
    logger.info(
        f"✅ Part 2 done via {provider2} — "
        f"{scene_count} scenes, {video_count} video prompts"
    )

    # ── MERGE both results ────────────────────────────────────────────────────
    # Start with part1 as base, overlay part2 on top
    merged = {**part1_result, **part2_result}

    # Always preserve image_prompts from part1 — never overwrite with part2
    merged["image_prompts"] = part1_result.get("image_prompts", [])

    # Always preserve character_bible from part1
    merged["character_bible"] = part1_result.get("character_bible", {})

    # Log final counts
    final_img  = len(merged.get("image_prompts", []))
    final_sc   = len(merged.get("scene_breakdown", []))
    final_vid  = len(merged.get("video_prompts", []))
    logger.info(
        f"✅ Merged: {final_sc} scenes | "
        f"{final_vid} video prompts | "
        f"{final_img} image prompts"
    )

    provider = f"{provider1}+{provider2}"
    return merged, provider
