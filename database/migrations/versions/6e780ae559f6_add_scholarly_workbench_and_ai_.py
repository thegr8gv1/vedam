"""add_scholarly_workbench_and_ai_tables

Revision ID: 6e780ae559f6
Revises: 8a95ab32600e
Create Date: 2026-11-04 20:11:39

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '6e780ae559f6'
down_revision: Union[str, Sequence[str], None] = '8a95ab32600e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Reviewer Profiles
    op.create_table(
        'reviewer_profiles',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('reviewer_id', sa.String(length=32), nullable=False),
        sa.Column('full_name', sa.String(length=128), nullable=False),
        sa.Column('email', sa.String(length=128), nullable=True),
        sa.Column('primary_role', sa.Enum(
            'SANSKRIT_TEXTUAL', 'VEDIC_RECENSION', 'HINDI_TRANSLATOR', 'TELUGU_TRANSLATOR',
            'TAMIL_TRANSLATOR', 'KANNADA_TRANSLATOR', 'MARATHI_TRANSLATOR', 'BENGALI_TRANSLATOR',
            'GUJARATI_TRANSLATOR', 'MALAYALAM_TRANSLATOR', 'ODIA_TRANSLATOR', 'AWADHI_SPECIALIST',
            'SANSKRIT_GRAMMAR', 'TRADITIONAL_COMMENTARY', 'LEGAL_COPYRIGHT', 'EDITORIAL_BOARD',
            name='reviewerrole'
        ), nullable=False),
        sa.Column('secondary_roles', sa.JSON(), nullable=True),
        sa.Column('areas_of_expertise', sa.JSON(), nullable=True),
        sa.Column('language_proficiency', sa.JSON(), nullable=True),
        sa.Column('sanskrit_proficiency', sa.String(length=64), server_default='Vidwan', nullable=False),
        sa.Column('vedic_specialization', sa.String(length=128), nullable=True),
        sa.Column('academic_qualifications', sa.String(length=255), nullable=True),
        sa.Column('institutional_affiliation', sa.String(length=255), nullable=True),
        sa.Column('is_credentials_verified', sa.Boolean(), server_default='0', nullable=False),
        sa.Column('verification_method', sa.String(length=128), nullable=True),
        sa.Column('verification_date', sa.DateTime(), nullable=True),
        sa.Column('permissions', sa.JSON(), nullable=True),
        sa.Column('is_active', sa.Boolean(), server_default='1', nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_reviewer_profiles_reviewer_id'), 'reviewer_profiles', ['reviewer_id'], unique=True)
    op.create_index(op.f('ix_reviewer_profiles_primary_role'), 'reviewer_profiles', ['primary_role'], unique=False)

    # 2. Review Assignments
    op.create_table(
        'review_assignments',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('assignment_id', sa.String(length=48), nullable=False),
        sa.Column('reviewer_id', sa.Integer(), nullable=False),
        sa.Column('text_id', sa.Integer(), nullable=False),
        sa.Column('verse_id', sa.Integer(), nullable=True),
        sa.Column('target_language', sa.String(length=16), nullable=False),
        sa.Column('view_type', sa.Enum(
            'LITERAL', 'BHAVARTHA', 'PADACHHEDA', 'TATPARYA', 'CULTURAL_NOTES',
            name='translationtype'
        ), nullable=True),
        sa.Column('priority', sa.Enum('LOW', 'NORMAL', 'HIGH', 'URGENT', name='assignmentpriority'), server_default='NORMAL', nullable=False),
        sa.Column('status', sa.Enum('PENDING', 'IN_PROGRESS', 'COMPLETED', 'REASSIGNED', 'DISPUTED', name='assignmentstatus'), server_default='PENDING', nullable=False),
        sa.Column('deadline', sa.DateTime(), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('assigned_by', sa.String(length=128), server_default='system_admin', nullable=False),
        sa.Column('assigned_at', sa.DateTime(), nullable=False),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
        sa.Column('reassigned_to_id', sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(['reviewer_id'], ['reviewer_profiles.id']),
        sa.ForeignKeyConstraint(['reassigned_to_id'], ['reviewer_profiles.id']),
        sa.ForeignKeyConstraint(['text_id'], ['texts.id']),
        sa.ForeignKeyConstraint(['verse_id'], ['verses.id']),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_review_assignments_assignment_id'), 'review_assignments', ['assignment_id'], unique=True)
    op.create_index(op.f('ix_review_assignments_reviewer_id'), 'review_assignments', ['reviewer_id'], unique=False)
    op.create_index(op.f('ix_review_assignments_text_id'), 'review_assignments', ['text_id'], unique=False)
    op.create_index(op.f('ix_review_assignments_verse_id'), 'review_assignments', ['verse_id'], unique=False)
    op.create_index(op.f('ix_review_assignments_target_language'), 'review_assignments', ['target_language'], unique=False)
    op.create_index(op.f('ix_review_assignments_status'), 'review_assignments', ['status'], unique=False)

    # 3. Review Action Logs
    op.create_table(
        'review_action_logs',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('action_id', sa.String(length=48), nullable=False),
        sa.Column('assignment_id', sa.Integer(), nullable=True),
        sa.Column('translation_id', sa.Integer(), nullable=False),
        sa.Column('translation_view_id', sa.Integer(), nullable=True),
        sa.Column('verse_id', sa.Integer(), nullable=False),
        sa.Column('reviewer_id', sa.Integer(), nullable=False),
        sa.Column('action_type', sa.Enum(
            'APPROVE', 'APPROVE_WITH_CORRECTIONS', 'REQUEST_REVISION', 'REJECT',
            'FLAG_UNCERTAINTY', 'FLAG_TERMINOLOGY', 'FLAG_MISSING_SOURCE', 'ESCALATE',
            name='reviewactiontype'
        ), nullable=False),
        sa.Column('previous_status', sa.String(length=32), nullable=False),
        sa.Column('new_status', sa.String(length=32), nullable=False),
        sa.Column('previous_text', sa.Text(), nullable=True),
        sa.Column('proposed_text', sa.Text(), nullable=True),
        sa.Column('scholarly_commentary', sa.Text(), nullable=False),
        sa.Column('traditional_references', sa.JSON(), nullable=True),
        sa.Column('alternative_readings', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['assignment_id'], ['review_assignments.id']),
        sa.ForeignKeyConstraint(['reviewer_id'], ['reviewer_profiles.id']),
        sa.ForeignKeyConstraint(['translation_id'], ['translations.id']),
        sa.ForeignKeyConstraint(['translation_view_id'], ['translation_views.id']),
        sa.ForeignKeyConstraint(['verse_id'], ['verses.id']),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_review_action_logs_action_id'), 'review_action_logs', ['action_id'], unique=True)
    op.create_index(op.f('ix_review_action_logs_reviewer_id'), 'review_action_logs', ['reviewer_id'], unique=False)
    op.create_index(op.f('ix_review_action_logs_translation_id'), 'review_action_logs', ['translation_id'], unique=False)
    op.create_index(op.f('ix_review_action_logs_verse_id'), 'review_action_logs', ['verse_id'], unique=False)
    op.create_index(op.f('ix_review_action_logs_action_type'), 'review_action_logs', ['action_type'], unique=False)

    # 4. Textual Disputes
    op.create_table(
        'textual_disputes',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('dispute_id', sa.String(length=48), nullable=False),
        sa.Column('verse_id', sa.Integer(), nullable=False),
        sa.Column('translation_id', sa.Integer(), nullable=True),
        sa.Column('translation_view_id', sa.Integer(), nullable=True),
        sa.Column('dispute_nature', sa.String(length=128), nullable=False),
        sa.Column('opinion_a_json', sa.JSON(), nullable=False),
        sa.Column('opinion_b_json', sa.JSON(), nullable=False),
        sa.Column('status', sa.Enum(
            'OPEN', 'UNDER_SECONDARY_REVIEW', 'REFERRED_TO_EDITORIAL_BOARD',
            'RESOLVED_PRESERVED_BOTH', 'RESOLVED_CONSENSUS',
            name='disputestatus'
        ), server_default='OPEN', nullable=False),
        sa.Column('editorial_resolution_notes', sa.Text(), nullable=True),
        sa.Column('resolved_by', sa.String(length=128), nullable=True),
        sa.Column('resolved_at', sa.DateTime(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['translation_id'], ['translations.id']),
        sa.ForeignKeyConstraint(['translation_view_id'], ['translation_views.id']),
        sa.ForeignKeyConstraint(['verse_id'], ['verses.id']),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_textual_disputes_dispute_id'), 'textual_disputes', ['dispute_id'], unique=True)
    op.create_index(op.f('ix_textual_disputes_verse_id'), 'textual_disputes', ['verse_id'], unique=False)
    op.create_index(op.f('ix_textual_disputes_status'), 'textual_disputes', ['status'], unique=False)

    # 5. AI Annotation Provenance
    op.create_table(
        'ai_annotation_provenances',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('annotation_id', sa.String(length=48), nullable=False),
        sa.Column('verse_id', sa.Integer(), nullable=False),
        sa.Column('annotation_type', sa.Enum(
            'PADACHHEDA', 'ANVAYA', 'GRAMMAR', 'WORD_MEANING', 'CHANDAS',
            'PRONUNCIATION', 'SOURCE_CITATION',
            name='aiannotationtype'
        ), nullable=False),
        sa.Column('provider_name', sa.String(length=64), nullable=False),
        sa.Column('model_version', sa.String(length=64), nullable=False),
        sa.Column('prompt_template_version', sa.String(length=64), nullable=True),
        sa.Column('prompt_hash', sa.String(length=64), nullable=True),
        sa.Column('output_payload_json', sa.JSON(), nullable=False),
        sa.Column('confidence_score', sa.Float(), server_default='0.0', nullable=False),
        sa.Column('is_suggestion_only', sa.Boolean(), server_default='1', nullable=False),
        sa.Column('is_human_reviewed', sa.Boolean(), server_default='0', nullable=False),
        sa.Column('human_reviewer_id', sa.Integer(), nullable=True),
        sa.Column('human_correction_notes', sa.Text(), nullable=True),
        sa.Column('estimated_cost_usd', sa.Float(), server_default='0.0', nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['human_reviewer_id'], ['reviewer_profiles.id']),
        sa.ForeignKeyConstraint(['verse_id'], ['verses.id']),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_ai_annotation_provenances_annotation_id'), 'ai_annotation_provenances', ['annotation_id'], unique=True)
    op.create_index(op.f('ix_ai_annotation_provenances_verse_id'), 'ai_annotation_provenances', ['verse_id'], unique=False)
    op.create_index(op.f('ix_ai_annotation_provenances_annotation_type'), 'ai_annotation_provenances', ['annotation_type'], unique=False)


def downgrade() -> None:
    op.drop_table('ai_annotation_provenances')
    op.drop_table('textual_disputes')
    op.drop_table('review_action_logs')
    op.drop_table('review_assignments')
    op.drop_table('reviewer_profiles')
