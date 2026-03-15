from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete, desc, func
from typing import Optional

from database import get_db
from models.user import User
from models.project import Project
from routers.auth import get_current_user

router = APIRouter(prefix="/projects", tags=["Projects"])


def project_to_dict(p: Project, include_result: bool = False) -> dict:
    data = {
        "id": p.id,
        "title": p.title,
        "idea": p.idea[:200] + "..." if len(p.idea) > 200 else p.idea,
        "content_type": p.content_type,
        "platform": p.platform,
        "duration_minutes": p.duration_minutes,
        "generator": p.generator,
        "generate_image_prompts": p.generate_image_prompts,
        "generate_voice_over": p.generate_voice_over,
        "status": p.status,
        "total_scenes": p.total_scenes,
        "clip_duration_seconds": p.clip_duration_seconds,
        "ai_provider_used": p.ai_provider_used,
        "created_at": p.created_at.isoformat() if p.created_at else None,
        "updated_at": p.updated_at.isoformat() if p.updated_at else None,
    }
    if include_result:
        data["result"] = p.result
    return data


@router.get("/")
async def list_projects(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    search: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(Project).where(Project.user_id == current_user.id)

    if search:
        query = query.where(Project.title.ilike(f"%{search}%"))
    if status:
        query = query.where(Project.status == status)

    query = query.order_by(desc(Project.created_at))

    # Count
    count_query = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_query)).scalar()

    # Paginate
    query = query.offset((page - 1) * limit).limit(limit)
    results = await db.execute(query)
    projects = results.scalars().all()

    return {
        "projects": [project_to_dict(p) for p in projects],
        "total": total,
        "page": page,
        "limit": limit,
        "pages": (total + limit - 1) // limit,
    }


@router.get("/{project_id}")
async def get_project(
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
    return project_to_dict(project, include_result=True)


@router.delete("/{project_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_project(
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
    await db.delete(project)


@router.get("/stats/summary")
async def get_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    total = (
        await db.execute(
            select(func.count()).where(Project.user_id == current_user.id)
        )
    ).scalar()
    completed = (
        await db.execute(
            select(func.count()).where(
                Project.user_id == current_user.id, Project.status == "completed"
            )
        )
    ).scalar()

    from datetime import date
    from sqlalchemy import cast, Date
    today_count = (
        await db.execute(
            select(func.count()).where(
                Project.user_id == current_user.id,
                func.date(Project.created_at) == date.today(),
            )
        )
    ).scalar()

    return {
        "total_projects": total,
        "completed_projects": completed,
        "today_count": today_count,
        "daily_limit": current_user.daily_limit,
        "plan": current_user.plan.value if hasattr(current_user.plan, 'value') else current_user.plan,
    }
