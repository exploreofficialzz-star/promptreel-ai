from sqlalchemy import Column, Integer, String, DateTime, Boolean, Enum as SAEnum, Date
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
import enum


class PlanType(str, enum.Enum):
    FREE = "free"
    CREATOR = "creator"
    STUDIO = "studio"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    name = Column(String(255), nullable=False)
    password_hash = Column(String(255), nullable=False)
    plan = Column(SAEnum(PlanType, native_enum=False), default=PlanType.FREE, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)

    # Rate limiting
    plans_generated_today = Column(Integer, default=0, nullable=False)
    last_generation_date = Column(Date, nullable=True)
    total_plans_generated = Column(Integer, default=0, nullable=False)

    # Subscription
    subscription_id = Column(String(255), nullable=True)
    subscription_expires_at = Column(DateTime(timezone=True), nullable=True)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    projects = relationship("Project", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User {self.email} [{self.plan}]>"

    @property
    def is_paid(self) -> bool:
        return self.plan in [PlanType.CREATOR, PlanType.STUDIO]

    @property
    def daily_limit(self) -> int:
        if self.is_paid:
            return -1  # Unlimited
        return 3

    @property
    def max_duration_minutes(self) -> int:
        if self.plan == PlanType.STUDIO:
            return 20
        elif self.plan == PlanType.CREATOR:
            return 20
        return 5  # Free
