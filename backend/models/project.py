from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, JSON, Text, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base


class Project(Base):
    __tablename__ = "projects"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    # Input
    title = Column(String(500), nullable=False)
    idea = Column(Text, nullable=False)
    content_type = Column(String(100), nullable=False)
    platform = Column(String(100), nullable=False)
    duration_minutes = Column(Integer, nullable=False)
    generator = Column(String(100), nullable=False)
    generate_image_prompts = Column(Boolean, default=False, nullable=False)
    generate_voice_over = Column(Boolean, default=False, nullable=False)

    # AI Output (stored as JSON)
    result = Column(JSON, nullable=True)
    ai_provider_used = Column(String(50), nullable=True)

    # Status
    status = Column(String(50), default="pending", nullable=False)  # pending, processing, completed, failed
    error_message = Column(Text, nullable=True)

    # Stats
    total_scenes = Column(Integer, default=0, nullable=False)
    clip_duration_seconds = Column(Integer, default=5, nullable=False)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="projects")

    def __repr__(self):
        return f"<Project {self.id}: {self.title[:50]}>"
