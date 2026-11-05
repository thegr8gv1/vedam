"""add_translation_views_table

Revision ID: 8a95ab32600e
Revises: c111d1f4a93d
Create Date: 2026-11-04 19:58:57.418404

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '8a95ab32600e'
down_revision: Union[str, Sequence[str], None] = 'c111d1f4a93d'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema to add translation_views table."""
    op.create_table(
        'translation_views',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('view_id', sa.String(length=64), nullable=False),
        sa.Column('translation_id', sa.Integer(), nullable=False),
        sa.Column('verse_id', sa.Integer(), nullable=False),
        sa.Column('target_language', sa.String(length=16), nullable=False),
        sa.Column('view_type', sa.Enum('LITERAL', 'BHAVARTHA', 'PADACHHEDA', 'TATPARYA', 'CULTURAL_NOTES', name='translationtype'), nullable=False),
        sa.Column('view_text', sa.Text(), nullable=False),
        sa.Column('version', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('source_reference', sa.String(length=255), nullable=True),
        sa.Column('translator_provenance', sa.String(length=255), nullable=True),
        sa.Column('review_status', sa.Enum('DRAFT', 'SCHOLAR_REVIEWED', 'APPROVED', name='reviewstatus'), nullable=False, server_default='DRAFT'),
        sa.Column('reviewer', sa.String(length=255), nullable=True),
        sa.Column('reviewer_affiliation', sa.String(length=255), nullable=True),
        sa.Column('reviewed_at', sa.DateTime(), nullable=True),
        sa.Column('approval_notes', sa.Text(), nullable=True),
        sa.Column('approval_history_json', sa.JSON(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('updated_at', sa.DateTime(), nullable=False),
        sa.ForeignKeyConstraint(['translation_id'], ['translations.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['verse_id'], ['verses.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('translation_id', 'view_type', 'version', name='uq_translation_view_type_version')
    )
    op.create_index(op.f('ix_translation_views_view_id'), 'translation_views', ['view_id'], unique=True)
    op.create_index(op.f('ix_translation_views_translation_id'), 'translation_views', ['translation_id'], unique=False)
    op.create_index(op.f('ix_translation_views_verse_id'), 'translation_views', ['verse_id'], unique=False)
    op.create_index(op.f('ix_translation_views_target_language'), 'translation_views', ['target_language'], unique=False)
    op.create_index(op.f('ix_translation_views_view_type'), 'translation_views', ['view_type'], unique=False)
    op.create_index(op.f('ix_translation_views_review_status'), 'translation_views', ['review_status'], unique=False)


def downgrade() -> None:
    """Downgrade schema by dropping translation_views table."""
    op.drop_index(op.f('ix_translation_views_review_status'), table_name='translation_views')
    op.drop_index(op.f('ix_translation_views_view_type'), table_name='translation_views')
    op.drop_index(op.f('ix_translation_views_target_language'), table_name='translation_views')
    op.drop_index(op.f('ix_translation_views_verse_id'), table_name='translation_views')
    op.drop_index(op.f('ix_translation_views_translation_id'), table_name='translation_views')
    op.drop_index(op.f('ix_translation_views_view_id'), table_name='translation_views')
    op.drop_table('translation_views')
