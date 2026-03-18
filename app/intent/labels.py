"""Intent labels and enums for the HSU QueryAI pipeline."""

from enum import Enum


class WorkspaceId(str, Enum):
    """Workspace identifiers."""
    LEAD_STATUS = "lead_status_enrollment"
    CONVERSATION = "conversation_insights"
    HOTLINE = "hotline_insights"
    STAFF = "staff_productivity"
    EXECUTIVE = "executive_summary"


class IntentLabel(str, Enum):
    """All intent labels across workspaces."""

    # Lead Status & Enrollment
    LEAD_CURRENT_STATUS = "lead_current_status"
    LEAD_COUNT_BY_STAGE = "lead_count_by_stage"
    LEAD_STAGE_CONVERSION = "lead_stage_conversion"
    LEAD_STAGNATION = "lead_stagnation"
    SCHOLARSHIP_PIPELINE = "scholarship_pipeline"
    TUITION_COMPLETION = "tuition_completion"
    MAJOR_INTEREST = "major_interest"
    ENROLLMENT_SUMMARY = "enrollment_summary"

    # Conversation Insights
    CONVERSATION_TOPICS = "conversation_topics"
    CONVERSATION_TOPIC_TREND = "conversation_topic_trend"
    CONVERSATION_SUMMARY = "conversation_summary"
    CONVERSATION_QUALITY = "conversation_quality"
    CARE_QUALITY_CHAT = "care_quality_chat"
    LEAD_INTEREST_FROM_CHAT = "lead_interest_from_chat"

    # Hotline Insights
    CALL_VOLUME = "call_volume"
    CALL_VOLUME_TREND = "call_volume_trend"
    CALL_TOPICS = "call_topics"
    CALL_QUALITY = "call_quality"
    CARE_QUALITY_HOTLINE = "care_quality_hotline"

    # Staff Productivity
    STAFF_LOGIN_STATUS = "staff_login_status"
    STAFF_RECENT_ACTIVITY = "staff_recent_activity"
    STAFF_TASK_STATUS = "staff_task_status"
    STAFF_PRODUCTIVITY_SUMMARY = "staff_productivity_summary"
    STAFF_CARE_ACTIVITY = "staff_care_activity"

    # Executive Admissions Summary
    EXECUTIVE_ADMISSIONS_OVERVIEW = "executive_admissions_overview"
    STAFF_RANKING = "staff_ranking"
    REVENUE_FORECAST = "revenue_forecast"
    CROSS_WORKSPACE_CARE_QUALITY = "cross_workspace_care_quality"
    ADMISSIONS_ALERTS = "admissions_alerts"


# Intent → Workspace mapping
INTENT_TO_WORKSPACE: dict[str, str] = {
    # Lead
    "lead_current_status": "lead_status_enrollment",
    "lead_count_by_stage": "lead_status_enrollment",
    "lead_stage_conversion": "lead_status_enrollment",
    "lead_stagnation": "lead_status_enrollment",
    "scholarship_pipeline": "lead_status_enrollment",
    "tuition_completion": "lead_status_enrollment",
    "major_interest": "lead_status_enrollment",
    "enrollment_summary": "lead_status_enrollment",
    # Conversation
    "conversation_topics": "conversation_insights",
    "conversation_topic_trend": "conversation_insights",
    "conversation_summary": "conversation_insights",
    "conversation_quality": "conversation_insights",
    "care_quality_chat": "conversation_insights",
    "lead_interest_from_chat": "conversation_insights",
    # Hotline
    "call_volume": "hotline_insights",
    "call_volume_trend": "hotline_insights",
    "call_topics": "hotline_insights",
    "call_quality": "hotline_insights",
    "care_quality_hotline": "hotline_insights",
    # Staff
    "staff_login_status": "staff_productivity",
    "staff_recent_activity": "staff_productivity",
    "staff_task_status": "staff_productivity",
    "staff_productivity_summary": "staff_productivity",
    "staff_care_activity": "staff_productivity",
    # Executive
    "executive_admissions_overview": "executive_summary",
    "staff_ranking": "executive_summary",
    "revenue_forecast": "executive_summary",
    "cross_workspace_care_quality": "executive_summary",
    "admissions_alerts": "executive_summary",
}
