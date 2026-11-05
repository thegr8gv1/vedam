"""add_phase8_reviewer_security_and_onboarding

Revision ID: 2ca2aa7fc304
Revises: 6e780ae559f6
Create Date: 2026-11-04 20:29:53.825088

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '2ca2aa7fc304'
down_revision: Union[str, Sequence[str], None] = '6e780ae559f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Add security & onboarding fields to reviewer_profiles
    with op.batch_alter_table('reviewer_profiles', schema=None) as batch_op:
        batch_op.add_column(sa.Column('password_hash', sa.String(length=255), nullable=True))
        batch_op.add_column(sa.Column('is_demonstration', sa.Boolean(), server_default='0', nullable=False))
        batch_op.add_column(sa.Column('verification_status', sa.String(length=32), server_default='PENDING_VERIFICATION', nullable=False))
        batch_op.add_column(sa.Column('verified_by_admin', sa.String(length=128), nullable=True))
        batch_op.add_column(sa.Column('verification_notes', sa.Text(), nullable=True))
        batch_op.add_column(sa.Column('last_login_at', sa.DateTime(), nullable=True))
        batch_op.add_column(sa.Column('failed_login_attempts', sa.Integer(), server_default='0', nullable=False))
        batch_op.add_column(sa.Column('is_locked', sa.Boolean(), server_default='0', nullable=False))

    # 2. Add feedback_category to review_action_logs
    with op.batch_alter_table('review_action_logs', schema=None) as batch_op:
        batch_op.add_column(sa.Column('feedback_category', sa.String(length=64), nullable=True))

    # 3. Create reviewer_sessions table
    op.create_table(
        'reviewer_sessions',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('session_token', sa.String(length=64), nullable=False),
        sa.Column('reviewer_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.Column('expires_at', sa.DateTime(), nullable=False),
        sa.Column('is_revoked', sa.Boolean(), server_default='0', nullable=False),
        sa.Column('client_ip', sa.String(length=64), nullable=True),
        sa.Column('user_agent', sa.String(length=255), nullable=True),
        sa.ForeignKeyConstraint(['reviewer_id'], ['reviewer_profiles.id'], ),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_reviewer_sessions_session_token'), 'reviewer_sessions', ['session_token'], unique=True)
    op.create_index(op.f('ix_reviewer_sessions_reviewer_id'), 'reviewer_sessions', ['reviewer_id'], unique=False)

    # 4. Create auth_audit_logs table
    op.create_table(
        'auth_audit_logs',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('reviewer_id', sa.Integer(), nullable=True),
        sa.Column('event_type', sa.String(length=64), nullable=False),
        sa.Column('ip_address', sa.String(length=64), nullable=True),
        sa.Column('details', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=False),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_auth_audit_logs_event_type'), 'auth_audit_logs', ['event_type'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_auth_audit_logs_event_type'), table_name='auth_audit_logs')
    op.drop_table('auth_audit_logs')

    op.drop_index(op.f('ix_reviewer_sessions_reviewer_id'), table_name='reviewer_sessions')
    op.drop_index(op.f('ix_reviewer_sessions_session_token'), table_name='reviewer_sessions')
    op.drop_table('reviewer_sessions')

    with op.batch_alter_table('review_action_logs', schema=None) as batch_op:
        batch_op.drop_column('feedback_category')

    with op.batch_alter_table('reviewer_profiles', schema=None) as batch_op:
        batch_op.drop_column('is_locked')
        batch_op.drop_column('failed_login_attempts')
        batch_op.drop_column('last_login_at')
        batch_op.drop_column('verification_notes')
        batch_op.drop_column('verified_by_admin')
        batch_op.drop_column('verification_status')
        batch_op.drop_column('is_demonstration')
        batch_op.drop_column('password_hash')
