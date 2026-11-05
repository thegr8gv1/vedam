"""add_phase11b_multilingual_reviewer_roles

Revision ID: e3a7b1c9f2d5
Revises: 9f3c8a1b2d4e
Create Date: 2026-11-05 04:45:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e3a7b1c9f2d5'
down_revision: Union[str, Sequence[str], None] = '9f3c8a1b2d4e'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

NEW_ROLES = [
    'ENGLISH_TRANSLATOR',
    'ASSAMESE_TRANSLATOR',
    'BODO_TRANSLATOR',
    'DOGRI_TRANSLATOR',
    'KASHMIRI_TRANSLATOR',
    'KONKANI_TRANSLATOR',
    'MAITHILI_TRANSLATOR',
    'MANIPURI_TRANSLATOR',
    'NEPALI_TRANSLATOR',
    'PUNJABI_TRANSLATOR',
    'SANTALI_TRANSLATOR',
    'SINDHI_TRANSLATOR',
    'URDU_TRANSLATOR',
]


def upgrade() -> None:
    """
    Expands the ReviewerRole enum to include the 13 new translator roles
    (12 Eighth Schedule expansion languages + English bridge language).
    For PostgreSQL, executes ALTER TYPE reviewerrole ADD VALUE.
    For SQLite, column type is VARCHAR(22) which natively supports all new values
    (length 15-19 chars) without requiring destructive table recreation.
    """
    bind = op.get_bind()
    dialect = bind.dialect.name

    if dialect == 'postgresql':
        for role in NEW_ROLES:
            op.execute(f"ALTER TYPE reviewerrole ADD VALUE IF NOT EXISTS '{role}'")
    else:
        # For SQLite and others, schema already accommodates the new string values.
        # Table recreation is avoided to prevent any accidental primary key or sequence mutation.
        pass


def downgrade() -> None:
    """
    Downgrade note:
    In PostgreSQL, enum values cannot be dropped with ALTER TYPE.
    In SQLite, since no destructive recreation was performed during upgrade,
    downgrade simply reverts the migration head tracking.
    """
    pass
