from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel, field_validator
from datetime import date
from typing import Optional, Dict
import asyncio
import logging

from database import get_db
from models.user import User
from models.project import Project
from routers.auth import get_current_user
from services.ai_service import generate_video_plan, calculate_scenes, get_clip_duration
from config import settings

router = APIRouter(prefix="/generate", tags=["Generation"])
logger = logging.getLogger(__name__)

VALID_CONTENT_TYPES = {
    "Educational", "Narration", "Commentary", "Documentary",
    "Storytelling", "Comedy", "Horror", "Motivational", "News", "Realistic"
}
VALID_PLATFORMS = {
    "YouTube", "TikTok", "Instagram", "Facebook", "YouTube Shorts", "X (Twitter)"
}
VALID_DURATIONS = {1, 3, 5, 10, 20}
VALID_GENERATORS = {"Runway", "Pika", "Kling", "Sora", "Luma", "Haiper", "Other"}


class GenerateRequest(BaseModel):
    idea: str
    content_type: str
    platform: str
    duration_minutes: int
    generator: str
    generate_image_prompts: bool = False
    generate_voice_over: bool = False
    content_type_options: Dict[str, str] = {}

    @field_validator("idea")
    @classmethod
    def validate_idea(cls, v):
        v = v.strip()
        if len(v) < 10:
            raise ValueError("Video idea must be at least 10 characters")
        if len(v) > 1000:
            raise ValueError("Video idea must be under 1000 characters")
        return v

    @field_validator("content_type")
    @classmethod
    def validate_content_type(cls, v):
        if v not in VALID_CONTENT_TYPES:
            raise ValueError(
                f"Invalid content type. Must be one of: {', '.join(VALID_CONTENT_TYPES)}"
            )
        return v

    @field_validator("platform")
    @classmethod
    def validate_platform(cls, v):
        if v not in VALID_PLATFORMS:
            raise ValueError(
                f"Invalid platform. Must be one of: {', '.join(VALID_PLATFORMS)}"
            )
        return v

    @field_validator("duration_minutes")
    @classmethod
    def validate_duration(cls, v):
        if v not in VALID_DURATIONS:
            raise ValueError(
                f"Invalid duration. Must be one of: "
                f"{', '.join(str(d) for d in sorted(VALID_DURATIONS))}"
            )
        return v

    @field_validator("generator")
    @classmethod
    def validate_generator(cls, v):
        if v not in VALID_GENERATORS:
            raise ValueError(
                f"Invalid generator. Must be one of: {', '.join(VALID_GENERATORS)}"
            )
        return v


async def check_limits(user: User, req: GenerateRequest, db: AsyncSession):
    """Enforce plan limits."""
    if user.is_paid:
        return

    if req.duration_minutes > settings.FREE_MAX_DURATION:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            f"Free plan supports videos up to {settings.FREE_MAX_DURATION} minutes. "
            f"Upgrade to Creator or Studio plan for longer videos.",
        )

    today = date.today()
    if user.last_generation_date != today:
        user.plans_generated_today = 0
        user.last_generation_date = today

    if user.plans_generated_today >= settings.FREE_DAILY_LIMIT:
        raise HTTPException(
            status.HTTP_429_TOO_MANY_REQUESTS,
            f"Daily limit of {settings.FREE_DAILY_LIMIT} plans reached. "
            "Upgrade to Creator plan for unlimited generations.",
        )


@router.post("/", status_code=status.HTTP_201_CREATED)
async def generate(
    req: GenerateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await check_limits(current_user, req, db)

    total_scenes  = calculate_scenes(req.duration_minutes, req.generator)
    clip_duration = get_clip_duration(req.generator)

    # Create project record immediately so we have an ID
    project = Project(
        user_id=current_user.id,
        title=f"Video: {req.idea[:80]}",
        idea=req.idea,
        content_type=req.content_type,
        platform=req.platform,
        duration_minutes=req.duration_minutes,
        generator=req.generator,
        generate_image_prompts=req.generate_image_prompts,
        generate_voice_over=req.generate_voice_over,
        total_scenes=total_scenes,
        clip_duration_seconds=clip_duration,
        status="processing",
    )
    db.add(project)
    await db.flush()
    await db.refresh(project)
    project_id = project.id

    logger.info(
        f"Starting generation | project={project_id} | "
        f"user={current_user.id} | type={req.content_type} | "
        f"duration={req.duration_minutes}min | scenes={total_scenes} | "
        f"images={req.generate_image_prompts} | vo={req.generate_voice_over} | "
        f"options={req.content_type_options}"
    )

    try:
        user_plan = (
            current_user.plan.value
            if hasattr(current_user.plan, "value")
            else current_user.plan
        )

        # ── Run generation with 280s timeout (just under Render's 300s limit) ──
        result, provider = await asyncio.wait_for(
            generate_video_plan(
                idea=req.idea,
                content_type=req.content_type,
                platform=req.platform,
                duration_minutes=req.duration_minutes,
                generator=req.generator,
                generate_image_prompts=req.generate_image_prompts,
                generate_voice_over=req.generate_voice_over,
                user_plan=user_plan,
                content_type_options=req.content_type_options,
            ),
            timeout=280,
        )

        # Extract best title from result
        titles = result.get("titles", {})
        title = (
            titles.get("primary")
            or titles.get("youtube")
            or f"Video: {req.idea[:80]}"
        )

        project.result          = result
        project.ai_provider_used = provider
        project.status          = "completed"
        project.title           = title[:500]

        current_user.total_plans_generated  += 1
        current_user.plans_generated_today  += 1
        current_user.last_generation_date    = date.today()

        await db.flush()
        logger.info(f"✅ Generation completed | project={project_id} | provider={provider}")

        return {
            "project_id":           project_id,
            "title":                title,
            "status":               "completed",
            "ai_provider":          provider,
            "total_scenes":         total_scenes,
            "clip_duration_seconds":clip_duration,
            "result":               result,
        }

    except asyncio.TimeoutError:
        project.status        = "failed"
        project.error_message = "Generation timed out after 280 seconds."
        await db.flush()
        logger.error(f"⏱️ Generation timed out | project={project_id}")
        raise HTTPException(
            status.HTTP_504_GATEWAY_TIMEOUT,
            "Generation timed out. Try a shorter video or fewer options.",
        )

    except Exception as e:
        project.status        = "failed"
        project.error_message = str(e)[:500]
        await db.flush()
        logger.error(f"❌ Generation failed | project={project_id} | error={e}")
        raise HTTPException(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            f"Generation failed: {str(e)}",
        )


@router.get("/preview")
async def preview_plan(
    duration_minutes: int = 5,
    generator: str = "Kling",
    current_user: User = Depends(get_current_user),
):
    """Preview scene count and clip info before generating."""
    clip_duration = get_clip_duration(generator)
    total_scenes  = calculate_scenes(duration_minutes, generator)
    detailed      = min(total_scenes, 60)

    # Estimate generation time based on batch count
    from services.ai_service import BATCH_SIZE
    import math
    batches       = math.ceil(detailed / BATCH_SIZE)
    # META + IMG batches + SCENE batches + VP batches + SCRIPT
    estimated_calls = 1 + batches + batches + batches + 1
    estimated_secs  = estimated_calls * 8  # ~8s per call average

    return {
        "duration_minutes":       duration_minutes,
        "generator":              generator,
        "clip_duration_seconds":  clip_duration,
        "total_scenes":           total_scenes,
        "detailed_scenes":        detailed,
        "estimated_api_calls":    estimated_calls,
        "estimated_time_seconds": estimated_secs,
    }
