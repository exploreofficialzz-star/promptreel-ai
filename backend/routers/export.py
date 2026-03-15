from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from database import get_db
from models.user import User
from models.project import Project
from routers.auth import get_current_user
from services.export_service import generate_export_zip
import logging

router = APIRouter(prefix="/export", tags=["Export"])
logger = logging.getLogger(__name__)


@router.get("/{project_id}/zip")
async def export_zip(
    project_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Project).where(
            Project.id == project_id, Project.user_id == current_user.id
        )
    )
    project = result.scalar_one_or_none()
    if not project:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Project not found")
    if project.status != "completed" or not project.result:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Project is not completed yet")

    try:
        project_data = {
            "idea": project.idea,
            "platform": project.platform,
            "content_type": project.content_type,
            "duration_minutes": project.duration_minutes,
            "generator": project.generator,
        }
        zip_bytes = generate_export_zip(project_data, project.result)
        filename = f"promptreel_{project_id}_{project.platform.lower()}.zip"

        return Response(
            content=zip_bytes,
            media_type="application/zip",
            headers={"Content-Disposition": f'attachment; filename="{filename}"'},
        )
    except Exception as e:
        logger.error(f"Export failed for project {project_id}: {e}")
        raise HTTPException(status.HTTP_500_INTERNAL_SERVER_ERROR, f"Export failed: {e}")


@router.get("/{project_id}/srt")
async def export_srt(
    project_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Export subtitles as SRT file."""
    result = await db.execute(
        select(Project).where(
            Project.id == project_id, Project.user_id == current_user.id
        )
    )
    project = result.scalar_one_or_none()
    if not project or not project.result:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Project not found")

    subtitle_script = project.result.get("subtitle_script", "")
    if not subtitle_script:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No subtitle script found")

    return Response(
        content=subtitle_script.encode("utf-8"),
        media_type="text/srt",
        headers={"Content-Disposition": f'attachment; filename="subtitles_{project_id}.srt"'},
    )


@router.get("/{project_id}/script")
async def export_script(
    project_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Export script as TXT file."""
    result = await db.execute(
        select(Project).where(
            Project.id == project_id, Project.user_id == current_user.id
        )
    )
    project = result.scalar_one_or_none()
    if not project or not project.result:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Project not found")

    script = project.result.get("full_script", "")
    return Response(
        content=script.encode("utf-8"),
        media_type="text/plain",
        headers={"Content-Disposition": f'attachment; filename="script_{project_id}.txt"'},
    )
