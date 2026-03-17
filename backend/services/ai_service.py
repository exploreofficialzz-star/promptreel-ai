"""
PromptReel AI — Multi-Provider AI Service
==========================================
Provider roster and plan-based routing:

  STUDIO  → GPT-4o  → Claude 3.5 Sonnet → Grok-2 → Gemini Pro → Mistral Large → DeepSeek
  CREATOR → GPT-4o-mini → Grok-2 → Gemini Pro → Mistral Large → Claude Sonnet → DeepSeek → Groq
  FREE    → Gemini Flash → Groq Llama 3.3 → DeepSeek-V3 → Together Qwen → OpenRouter Free → GPT-4o-mini

All providers share the same JSON-only prompt and a structured fallback chain.
A provider that fails (quota, network, invalid JSON) is automatically skipped.
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
    """xAI Grok — uses OpenAI-compatible API at api.x.ai"""
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
    """Mistral AI — native REST API."""
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
    """DeepSeek-V3 — OpenAI-compatible at api.deepseek.com."""
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
    """Groq — ultra-fast inference. Llama 3.3 70B."""
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
    """Together AI — Qwen 2.5 72B."""
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
    """OpenRouter — free model gateway."""
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
            ("gemini-1.5-pro",      call_gemini,    s.GEMINI_MODEL_CREATOR,   s.GEMINI_API_KEY),
            ("mistral-large",       call_mistral,   s.MISTRAL_MODEL_CREATOR,  s.MISTRAL_API_KEY),
            ("deepseek-v3",         call_deepseek,  s.DEEPSEEK_MODEL_FREE,    s.DEEPSEEK_API_KEY),
            ("groq-llama3.3-70b",   call_groq,      s.GROQ_MODEL_FREE,        s.GROQ_API_KEY),
            ("together-qwen2.5",    call_together,  s.TOGETHER_MODEL_FREE,    s.TOGETHER_API_KEY),
        ],
        "creator": [
            ("openai-gpt4o-mini",   call_openai,    s.OPENAI_MODEL_CREATOR,   s.OPENAI_API_KEY),
            ("grok-2",              call_grok,      s.GROK_MODEL_CREATOR,     s.GROK_API_KEY),
            ("gemini-1.5-pro",      call_gemini,    s.GEMINI_MODEL_CREATOR,   s.GEMINI_API_KEY),
            ("mistral-large",       call_mistral,   s.MISTRAL_MODEL_CREATOR,  s.MISTRAL_API_KEY),
            ("anthropic-sonnet3.5", call_anthropic, s.ANTHROPIC_MODEL_STUDIO, s.ANTHROPIC_API_KEY),
            ("deepseek-v3",         call_deepseek,  s.DEEPSEEK_MODEL_FREE,    s.DEEPSEEK_API_KEY),
            ("groq-llama3.3-70b",   call_groq,      s.GROQ_MODEL_FREE,        s.GROQ_API_KEY),
            ("together-qwen2.5",    call_together,  s.TOGETHER_MODEL_FREE,    s.TOGETHER_API_KEY),
        ],
        "free": [
            ("gemini-1.5-flash",    call_gemini,    s.GEMINI_MODEL_FREE,      s.GEMINI_API_KEY),
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


# ─── Character Bible Builder ──────────────────────────────────────────────────
def build_character_bible(idea: str, content_type: str) -> str:
    return f"""
━━━ CHARACTER BIBLE — READ THIS FIRST ━━━
CRITICAL CONSISTENCY RULE: You MUST extract ALL characters, creatures,
objects, and locations from the idea below and define their EXACT physical
details. These details are LOCKED and must NEVER change across any scene.

IDEA: {idea}
TYPE: {content_type}

For EVERY character/creature/object that appears in this video you MUST:

1. Give them a unique identifier name (e.g. "MAIN_CAT", "VILLAIN", "HERO")
2. Lock their physical appearance with these details:
   - Species/type (e.g. domestic shorthair cat, golden retriever, human male)
   - Size & build (e.g. small, 3kg, slender body)
   - Color & markings (e.g. jet black fur, NO white patches, green eyes)
   - Distinguishing features (e.g. torn left ear, scar on nose, blue collar)
   - Clothing/accessories if applicable
   - Age appearance (e.g. young adult, elderly, kitten)
   - Movement style (e.g. graceful, limping, energetic)

3. In EVERY scene_breakdown visual_description, REPEAT the character's
   locked details. Example:
   WRONG: "The cat walks through the forest"
   RIGHT: "MAIN_CAT — jet black domestic shorthair, green eyes, blue collar,
           small 3kg frame — stalks through the misty forest, ears flat"

4. In EVERY video_prompt, START with the character reference. Example:
   WRONG: "A cat running in the rain"
   RIGHT: "Consistent character: jet black small domestic shorthair cat,
           vivid green eyes, worn blue leather collar, 3kg slender frame —
           sprinting through heavy rain, photorealistic, 4K cinematic"

5. In EVERY image_prompt use your character_bible definitions to write
   a REAL complete prompt. Example of correct image prompt output:
   MIDJOURNEY: "jet black domestic shorthair cat, vivid green almond eyes,
   worn blue leather collar, small 3kg slender frame, stalking through
   misty ancient forest at golden hour, cinematic --ar 16:9 --v 6.1 --q 2"

ENVIRONMENT CONSISTENCY: Lock locations — same trees, lighting,
atmosphere every time that location reappears.

STYLE CONSISTENCY: Lock visual style — cinematic style, color grading,
lighting mood — applies to EVERY scene and prompt.

⚠️ VIOLATION WARNING: Any character changing color, size, species,
or appearance between scenes = CRITICAL ERROR.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"""


# ─── Generation Prompt ────────────────────────────────────────────────────────
def build_generation_prompt(
    idea: str,
    content_type: str,
    platform: str,
    duration_minutes: int,
    generator: str,
    clip_duration: int,
    total_scenes: int,
    generate_image_prompts: bool,
    generate_voice_over: bool,
    content_type_options: dict = {},
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
    generator_tips = {
        "Runway":  "'tracking shot', 'dolly zoom', '4K cinematic', 'photorealistic'",
        "Pika":    "'smooth motion', 'fluid movement', short descriptions",
        "Kling":   "'10-second loop', 'seamless motion', detailed scenes",
        "Sora":    "rich narrative descriptions, complex layouts",
        "Luma":    "'3D', 'depth of field', 'cinematic grade'",
        "Haiper":  "motion-first, particle effects, 'high fps'",
        "Other":   "detailed scene: style, lighting, camera angle, subject",
    }

    # ── Image prompts block ───────────────────────────────────────────────────
    # Use concrete filled examples so AI generates real content not instructions
    if generate_image_prompts:
        img_block = f'''  "image_prompts": [
    {{
      "scene_number": 1,
      "midjourney": "Using your character_bible definitions above, output a real Midjourney prompt like this example (replace with your actual character): jet black domestic shorthair cat, vivid green almond eyes, worn blue leather collar, small 3kg slender frame, stalking through misty ancient forest at golden hour, dappled oak canopy light, ground fog, cinematic, photorealistic, ultra-detailed --ar 16:9 --v 6.1 --style raw --q 2",
      "stable_diffusion": "Using your character_bible definitions above, output a real Stable Diffusion prompt like this example (replace with your actual character): jet black domestic shorthair cat, vivid green almond eyes, worn blue leather collar, small slender frame, misty forest, golden hour light, fog, masterpiece, best quality, ultra-detailed, photorealistic, 8K, cinematic lighting, sharp focus",
      "leonardo": "Using your character_bible definitions above, output a real Leonardo AI prompt like this example (replace with your actual character): jet black small domestic shorthair cat with vivid green eyes and worn blue collar, stalking through ancient misty forest, golden hour dappled light, detailed fur texture, cinematic composition, professional wildlife photography, highly detailed",
      "dall_e": "Using your character_bible definitions above, output a real DALL-E 3 prompt like this example (replace with your actual character): A photorealistic image of a small jet black domestic shorthair cat with vivid green almond eyes and a worn blue leather collar, stalking low through a misty ancient forest at golden hour, soft dappled light through oak canopy, ground fog swirling around its paws, cinematic mood",
      "purpose": "establishing_shot"
    }}
  ],'''
    else:
        img_block = '  "image_prompts": [],'

    # ── Voice-over block ──────────────────────────────────────────────────────
    if generate_voice_over:
        vo = (
            f"Write the complete {duration_minutes}-minute timed voice-over "
            f"script with a timestamp every 10 seconds from [00:00] to "
            f"[{duration_minutes:02d}:00]. "
            f"Example format:\n"
            f"[00:00] Opening line that grabs attention immediately.\n"
            f"[00:10] Build on the opening with compelling detail.\n"
            f"[00:20] Continue developing the narrative with energy.\n"
            f"Replace these example lines with real narration for the idea. "
            f"Minimum {duration_minutes * 130} words total."
        )
    else:
        vo = "Not requested"

    # ── Content type options block ────────────────────────────────────────────
    content_options_block = ""
    if content_type_options:
        opts = "\n".join([
            f"  {k.replace('_', ' ').upper()}: {v}"
            for k, v in content_type_options.items()
        ])
        content_options_block = f"\nCONTENT SETTINGS (MUST be applied to all output):\n{opts}"

    character_bible = build_character_bible(idea, content_type)

    return f"""You are PromptReel AI — the world's most advanced AI video content strategist.
You specialize in creating fully consistent video production packages where every
character, creature, and location stays IDENTICAL across every single scene.

{character_bible}

━━━ VIDEO BRIEF ━━━
IDEA: {idea}
TYPE: {content_type} — {tone_map.get(content_type, "engaging")}
PLATFORM: {platform} — {platform_tips.get(platform, "")}
DURATION: {duration_minutes} minutes
GENERATOR: {generator} ({clip_duration}s clips) — {generator_tips.get(generator, "")}
SCENES: {total_scenes} total (provide {detailed_scenes} detailed)
IMAGE PROMPTS: {"YES" if generate_image_prompts else "NO"}
VOICE-OVER: {"YES" if generate_voice_over else "NO"}{content_options_block}
━━━━━━━━━━━━━━━━━

STEP 1: Extract ALL characters from the idea. Define their exact locked
appearance in character_bible — be very specific about every detail.

STEP 2: Use those locked details WORD FOR WORD in every scene,
every video prompt, and every image prompt.

STEP 3: Apply ALL content settings to narrator voice, accent, pace, style.

STEP 4: Return ONLY valid JSON. No markdown. No explanation. Pure JSON.

CRITICAL IMAGE PROMPT RULE:
The image_prompts template shows EXAMPLE prompts using a cat character.
You MUST replace the cat example with YOUR actual character details from
character_bible. Output real copy-paste ready prompts — never output
the word "example" or any instructions in the final JSON values.

CORRECT image prompt output example:
"medium-build male narrator, short black hair, brown eyes, silver watch,
black glasses, standing in futuristic cityscape, neon lights, cinematic
lighting, photorealistic --ar 16:9 --v 6.1 --style raw --q 2"

WRONG image prompt output:
"Using your character_bible definitions above, output a real prompt..."

{{
  "character_bible": {{
    "characters": [
      {{
        "id": "NARRATOR",
        "name": "Main Narrator",
        "type": "human male presenter",
        "appearance": {{
          "size": "medium build, 180cm, athletic",
          "colors": "light brown skin, black hair",
          "markings": "none",
          "eyes": "dark brown, sharp focused gaze",
          "distinctive_features": "strong jawline, confident posture",
          "accessories": "silver watch, black-rimmed glasses"
        }},
        "movement_style": "confident, purposeful strides",
        "personality_visual": "commands attention, direct eye contact"
      }}
    ],
    "locations": [
      {{
        "id": "MAIN_LOCATION",
        "name": "Primary Setting",
        "description": "detailed description of the main environment",
        "lighting": "specific lighting setup",
        "atmosphere": "mood and atmosphere"
      }}
    ],
    "visual_style": {{
      "style": "photorealistic cinematic",
      "color_grading": "warm tones with deep shadows",
      "lighting_mood": "dramatic directional lighting",
      "consistency_seed": "cinematic photorealistic warm dramatic"
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
  "viral_hook": "2-3 sentence shocking/provocative opener.",
  "thumbnail_prompt": "Real thumbnail prompt using actual locked character: [exact character description], bold yellow text '[3 word hook]', [background], high contrast cinematic grade, rule of thirds. Min 50 words.",
  "youtube_seo": {{
    "title": "SEO title with exact-match keyword at start",
    "description": "Full 1500+ char description with emoji bullets, timestamps, CTA",
    "tags": ["tag1","tag2","tag3","tag4","tag5","tag6","tag7","tag8","tag9","tag10","tag11","tag12","tag13","tag14","tag15","tag16","tag17","tag18","tag19","tag20"],
    "category": "most appropriate YouTube category"
  }},
  "hashtags": {{
    "primary": ["#Tag1","#Tag2","#Tag3","#Tag4","#Tag5"],
    "secondary": ["#Tag6","#Tag7","#Tag8","#Tag9","#Tag10","#Tag11","#Tag12","#Tag13","#Tag14","#Tag15"],
    "niche": ["#Tag16","#Tag17","#Tag18","#Tag19","#Tag20","#Tag21","#Tag22","#Tag23","#Tag24","#Tag25"],
    "trending": ["#Tag26","#Tag27","#Tag28","#Tag29","#Tag30"]
  }},
  "subtitle_script": "1\\n00:00:00,000 --> 00:00:{clip_duration:02d},000\\nOpening narration text here\\n\\n2\\n00:00:{clip_duration:02d},000 --> 00:00:{clip_duration*2:02d},000\\nContinuing narration text here",
  "voice_over_script": "{vo}",
  "production_notes": {{
    "total_scenes_needed": {total_scenes},
    "detailed_scenes_provided": {detailed_scenes},
    "clip_duration_seconds": {clip_duration},
    "estimated_word_count": {duration_minutes * 130},
    "recommended_editing_tool": "CapCut or DaVinci Resolve",
    "pro_tips": [
      "Character consistency tip for {generator}",
      "Tip specific to {platform}",
      "Retention tip",
      "Monetization tip"
    ]
  }},
  "full_script": "Complete {duration_minutes}-minute narration with [SCENE X] markers. Min {duration_minutes * 130} words. Match narrator voice/accent from content settings.",
  "scene_breakdown": [
    {{
      "scene_number": 1,
      "time_start": "0:00",
      "time_end": "0:{clip_duration:02d}",
      "title": "Evocative scene title",
      "visual_description": "CHARACTER_ID (exact locked appearance) — action. Setting: LOCATION_ID (locked environment details). Camera: angle.",
      "narration_text": "Exact narrator words for this scene matching voice/accent settings",
      "mood": "intense/mysterious/dramatic/inspiring",
      "b_roll_suggestion": "Supplementary footage maintaining character consistency",
      "transition": "cut/fade/zoom"
    }}
  ],
  "video_prompts": [
    {{
      "scene_number": 1,
      "prompt": "Character locked appearance — scene action, locked environment, camera movement, locked lighting, locked visual style, {generator} optimized, photorealistic, 4K, ultra-detailed, character consistency",
      "negative_prompt": "inconsistent character, different appearance, character change, blurry, text, watermark, low quality",
      "camera_work": "specific camera movement",
      "lighting": "lighting matching character_bible visual_style",
      "style_tags": ["consistent character", "cinematic", "photorealistic", "4K"],
      "duration": "{clip_duration}s"
    }}
  ],
{img_block}
}}

FINAL RULES:
- character_bible defines LOCKED appearances — never deviate
- content settings MUST be applied to narrator voice, accent, pace, style
- Every scene visual_description MUST reference character ID + full appearance
- Every video_prompt MUST start with the character's full locked description
- image_prompts MUST contain real copy-paste ready prompts using your actual
  character details — NEVER output instructions or the word "example" in values
- voice_over_script MUST be real timed [MM:SS] narration every 10 seconds
- Generate ALL {detailed_scenes} scene_breakdown entries
- Generate ALL {detailed_scenes} video_prompts
- Pure JSON only — no markdown, no explanation"""


def parse_json_response(raw: str) -> dict:
    cleaned = re.sub(r"```json\s*", "", raw)
    cleaned = re.sub(r"```\s*", "", cleaned).strip()
    start, end = cleaned.find("{"), cleaned.rfind("}") + 1
    if start != -1 and end > start:
        cleaned = cleaned[start:end]
    return json.loads(cleaned)


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

    prompt = build_generation_prompt(
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

    chain = get_provider_chain(user_plan)
    if not chain:
        raise ValueError(
            "No AI API keys configured. Set at least one of: "
            "GEMINI_API_KEY, GROQ_API_KEY, DEEPSEEK_API_KEY, OPENAI_API_KEY, "
            "GROK_API_KEY, ANTHROPIC_API_KEY, MISTRAL_API_KEY, "
            "TOGETHER_API_KEY, OPENROUTER_API_KEY"
        )

    logger.info(f"[{user_plan.upper()}] Starting. Chain: {[p[0] for p in chain]}")
    last_error = None
    for label, caller, model in chain:
        try:
            logger.info(f"  → {label} ({model})")
            raw    = await caller(prompt, model)
            result = parse_json_response(raw)
            logger.info(f"  ✅ {label}")
            return result, label
        except json.JSONDecodeError as e:
            logger.warning(f"  ✗ {label}: bad JSON — {e}")
            last_error = e
        except Exception as e:
            logger.warning(f"  ✗ {label}: {type(e).__name__} — {e}")
            last_error = e

    raise RuntimeError(
        f"All AI providers failed for [{user_plan}] plan. Last: {last_error}"
)
