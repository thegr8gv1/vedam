"""add_phase9_authenticity_and_session_hardening

Revision ID: 9f3c8a1b2d4e
Revises: 2ca2aa7fc304
Create Date: 2026-11-04 21:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9f3c8a1b2d4e'
down_revision: Union[str, Sequence[str], None] = '2ca2aa7fc304'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add human authenticity fields to reviewer_profiles
    with op.batch_alter_table('reviewer_profiles', schema=None) as batch_op:
        batch_op.add_column(sa.Column('account_category', sa.String(length=50), server_default='SYNTHETIC_TEST_PERSONA', nullable=False))
        batch_op.add_column(sa.Column('is_human_verified', sa.Boolean(), server_default='0', nullable=False))
        batch_op.add_column(sa.Column('verification_doc_hash', sa.String(length=128), nullable=True))
        batch_op.add_column(sa.Column('verification_authority', sa.String(length=255), nullable=True))

    # 2. Add activity and absolute expiration to reviewer_sessions
    with op.batch_alter_table('reviewer_sessions', schema=None) as batch_op:
        batch_op.add_column(sa.Column('last_activity_at', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('absolute_expires_at', sa.DateTime(), nullable=True))

    # 3. Add immutability verification and human flag to review_action_logs
    with op.batch_alter_table('review_action_logs', schema=None) as batch_op:
        batch_op.add_column(sa.Column('original_text_immutable_verified', sa.Boolean(), server_default='1', nullable=False))
        batch_op.add_column(sa.Column('is_human_review', sa.Boolean(), server_default='0', nullable=False))


def downgrade() -> None:
    with op.batch_alter_table('review_action_logs', schema=None) as batch_op:
        batch_op.drop_column('is_human_review')
        batch_op.drop_column('original_text_immutable_verified')

    with op.batch_alter_table('reviewer_sessions', schema=None) as batch_op:
        batch_op.drop_column('absolute_expires_at')
        batch_op.drop_column('last_activity_at')

    with op.batch_alter_table('reviewer_profiles', schema=None) as batch_op:
        batch_op.drop_column('verification_authority')
        batch_op.drop_column('verification_doc_hash')
        batch_op.drop_column('is_human_verified')
        batch_op.drop_column('account_category')
