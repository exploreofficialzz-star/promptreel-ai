import io
import zipfile
import json
from typing import Optional


def format_scene_breakdown(scenes: list) -> str:
    lines = ["SCENE BREAKDOWN", "=" * 60, ""]
    for scene in scenes:
        lines.append(f"Scene {scene.get('scene_number', '?')} │ {scene.get('time_start', '')} — {scene.get('time_end', '')}")
        lines.append(f"Title: {scene.get('title', '')}")
        lines.append(f"Visual: {scene.get('visual_description', '')}")
        lines.append(f"Narration: {scene.get('narration_text', '')}")
        lines.append(f"Mood: {scene.get('mood', '')}")
        if scene.get("transition"):
            lines.append(f"Transition: {scene.get('transition')}")
        lines.append("-" * 40)
    return "\n".join(lines)


def format_video_prompts(prompts: list) -> str:
    lines = ["VIDEO GENERATION PROMPTS", "=" * 60, ""]
    for p in prompts:
        lines.append(f"── SCENE {p.get('scene_number', '?')} [{p.get('duration', '5s')}] ──")
        lines.append(f"PROMPT:\n{p.get('prompt', '')}")
        if p.get("negative_prompt"):
            lines.append(f"NEGATIVE: {p.get('negative_prompt')}")
        if p.get("camera_work"):
            lines.append(f"CAMERA: {p.get('camera_work')}")
        if p.get("lighting"):
            lines.append(f"LIGHTING: {p.get('lighting')}")
        if p.get("style_tags"):
            lines.append(f"STYLE: {', '.join(p.get('style_tags', []))}")
        lines.append("")
    return "\n".join(lines)


def format_image_prompts(prompts: list) -> str:
    if not prompts:
        return "Image prompts were not requested for this project."
    lines = ["IMAGE GENERATION PROMPTS", "=" * 60, ""]
    for p in prompts:
        lines.append(f"── SCENE {p.get('scene_number', '?')} ──")
        if p.get("midjourney"):
            lines.append(f"MIDJOURNEY:\n{p.get('midjourney')}")
        if p.get("stable_diffusion"):
            lines.append(f"STABLE DIFFUSION:\n{p.get('stable_diffusion')}")
        if p.get("leonardo"):
            lines.append(f"LEONARDO AI:\n{p.get('leonardo')}")
        if p.get("dall_e"):
            lines.append(f"DALL-E:\n{p.get('dall_e')}")
        lines.append(f"PURPOSE: {p.get('purpose', '')}")
        lines.append("")
    return "\n".join(lines)


def format_youtube_seo(seo: dict) -> str:
    tags = seo.get("tags", [])
    lines = [
        "YOUTUBE SEO PACKAGE",
        "=" * 60,
        "",
        "TITLE:",
        seo.get("title", ""),
        "",
        "DESCRIPTION:",
        seo.get("description", ""),
        "",
        "TAGS:",
        ", ".join(tags),
        "",
        f"CATEGORY: {seo.get('category', '')}",
    ]
    return "\n".join(lines)


def format_hashtags(hashtags: dict) -> str:
    if isinstance(hashtags, list):
        return "HASHTAGS\n" + "=" * 60 + "\n\n" + " ".join(hashtags)
    lines = ["HASHTAGS", "=" * 60, ""]
    for category, tags in hashtags.items():
        if tags:
            lines.append(f"{category.upper()}:")
            lines.append(" ".join(tags))
            lines.append("")
    return "\n".join(lines)


def generate_export_zip(project_data: dict, result: dict) -> bytes:
    """Generate a ZIP file containing all project files."""
    zip_buffer = io.BytesIO()
    idea_slug = project_data.get("idea", "video")[:30].replace(" ", "_").lower()
    folder = f"promptreel_{idea_slug}/"

    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zf:
        # 1. Full Script
        full_script = result.get("full_script", "")
        if full_script:
            zf.writestr(
                f"{folder}script.txt",
                f"FULL SCRIPT — PromptReel AI\n{'='*60}\n\n{full_script}"
            )

        # 2. Scene Breakdown
        scenes = result.get("scene_breakdown", [])
        if scenes:
            zf.writestr(f"{folder}scene_breakdown.txt", format_scene_breakdown(scenes))

        # 3. Video Prompts
        video_prompts = result.get("video_prompts", [])
        if video_prompts:
            zf.writestr(f"{folder}video_prompts.txt", format_video_prompts(video_prompts))

        # 4. Image Prompts
        image_prompts = result.get("image_prompts", [])
        image_content = format_image_prompts(image_prompts)
        zf.writestr(f"{folder}image_prompts.txt", image_content)

        # 5. Voice-Over Script
        voice_over = result.get("voice_over_script", "")
        if voice_over and voice_over != "Not requested":
            zf.writestr(
                f"{folder}voice_over_script.txt",
                f"VOICE-OVER SCRIPT — PromptReel AI\n{'='*60}\n\n{voice_over}"
            )

        # 6. YouTube SEO
        youtube_seo = result.get("youtube_seo", {})
        if youtube_seo:
            zf.writestr(f"{folder}youtube_seo.txt", format_youtube_seo(youtube_seo))

        # 7. Hashtags
        hashtags = result.get("hashtags", {})
        if hashtags:
            zf.writestr(f"{folder}hashtags.txt", format_hashtags(hashtags))

        # 8. Thumbnail Prompt
        thumbnail = result.get("thumbnail_prompt", "")
        if thumbnail:
            zf.writestr(
                f"{folder}thumbnail_prompt.txt",
                f"THUMBNAIL PROMPT — PromptReel AI\n{'='*60}\n\n{thumbnail}"
            )

        # 9. Titles
        titles = result.get("titles", {})
        viral_hook = result.get("viral_hook", "")
        titles_content = "TITLES & HOOK — PromptReel AI\n" + "=" * 60 + "\n\n"
        for platform, title in titles.items():
            titles_content += f"{platform.upper()}: {title}\n"
        if viral_hook:
            titles_content += f"\nVIRAL HOOK:\n{viral_hook}\n"
        zf.writestr(f"{folder}titles_and_hook.txt", titles_content)

        # 10. Subtitles SRT
        subtitle_script = result.get("subtitle_script", "")
        if subtitle_script:
            zf.writestr(f"{folder}subtitles.srt", subtitle_script)

        # 11. Production Notes
        notes = result.get("production_notes", {})
        if notes:
            notes_content = "PRODUCTION NOTES — PromptReel AI\n" + "=" * 60 + "\n\n"
            notes_content += json.dumps(notes, indent=2)
            zf.writestr(f"{folder}production_notes.txt", notes_content)

        # 12. Full JSON (for developers)
        zf.writestr(
            f"{folder}full_data.json",
            json.dumps(result, indent=2, ensure_ascii=False)
        )

        # 13. README
        readme = f"""PromptReel AI — Video Production Package
{'='*60}

PROJECT: {project_data.get('idea', '')[:100]}
PLATFORM: {project_data.get('platform', '')}
CONTENT TYPE: {project_data.get('content_type', '')}
DURATION: {project_data.get('duration_minutes', '')} minutes
GENERATOR: {project_data.get('generator', '')}

FILES IN THIS PACKAGE:
• script.txt — Complete narration script
• scene_breakdown.txt — Scene-by-scene breakdown
• video_prompts.txt — AI video generation prompts
• image_prompts.txt — AI image generation prompts
• voice_over_script.txt — Voice-over text (if requested)
• youtube_seo.txt — Title, description, tags
• hashtags.txt — Platform hashtags
• thumbnail_prompt.txt — Thumbnail generation prompt
• titles_and_hook.txt — All title variations + viral hook
• subtitles.srt — Subtitle file
• production_notes.txt — Tips and production notes
• full_data.json — Complete data in JSON format

Generated by PromptReel AI — Made with ❤️ by chAs Tech Group
https://promptreel.ai
"""
        zf.writestr(f"{folder}README.txt", readme)

    zip_buffer.seek(0)
    return zip_buffer.getvalue()
