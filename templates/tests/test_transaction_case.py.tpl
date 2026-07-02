# Test Template — TransactionCase (Backend) — Odoo 16.0–19.0
# Replace all {{ placeholders }} with actual values.
#
# USAGE:
#   - Place this file in: {{ module_name }}/tests/test_{{ model_underscore }}.py
#   - Import it in:       {{ module_name }}/tests/__init__.py
#   - Run with:           odoo-bin -d <db> -i {{ module_name }} --test-enable --stop-after-init
#
# TAGS:
#   @tagged("post_install", "-at_install") → runs AFTER module install
#   @tagged("at_install")                  → runs DURING install (default)

from odoo.exceptions import UserError, ValidationError
from odoo.tests.common import Form, TransactionCase
from odoo.tests import tagged

import logging

_logger = logging.getLogger(__name__)


@tagged("post_install", "-at_install")
class Test{{ ModelClassName }}(TransactionCase):
    """Tests for {{ model.name }} model."""

    @classmethod
    def setUpClass(cls):
        """Shared test fixtures — created once for all tests in this class."""
        super().setUpClass()

        cls.partner = cls.env["res.partner"].create({
            "name": "Test Partner",
            "email": "test@example.com",
        })

        cls.{{ model_var }} = cls.env["{{ model.name }}"].create({
            "name": "Test {{ ModelClassName }}",
            "company_id": cls.env.company.id,
            # Add required fields here
        })

    # =========================================================================
    # CRUD Tests
    # =========================================================================

    def test_create_{{ model_underscore }}(self):
        """Test: create a new record with required fields."""
        record = self.env["{{ model.name }}"].create({
            "name": "New Test Record",
            "company_id": self.env.company.id,
        })
        self.assertTrue(record.exists(), "Record should exist after creation.")
        self.assertEqual(record.state, "draft", "Default state should be 'draft'.")

    def test_read_{{ model_underscore }}(self):
        """Test: read record fields."""
        self.assertEqual(self.{{ model_var }}.name, "Test {{ ModelClassName }}")
        self.assertIsNotNone(self.{{ model_var }}.create_date)

    def test_write_{{ model_underscore }}(self):
        """Test: update a record field."""
        new_name = "Updated Name"
        self.{{ model_var }}.write({"name": new_name})
        self.assertEqual(self.{{ model_var }}.name, new_name)

    def test_unlink_{{ model_underscore }}_draft(self):
        """Test: delete a record in draft state."""
        temp = self.env["{{ model.name }}"].create({"name": "To Delete"})
        temp_id = temp.id
        temp.unlink()
        self.assertFalse(
            self.env["{{ model.name }}"].browse(temp_id).exists(),
            "Record should not exist after deletion.",
        )

    def test_unlink_{{ model_underscore }}_confirmed_raises(self):
        """Test: delete a confirmed record should raise UserError."""
        self.{{ model_var }}.action_confirm()
        with self.assertRaises(UserError):
            self.{{ model_var }}.unlink()
        # Reset for other tests
        self.{{ model_var }}.action_reset_to_draft()

    # =========================================================================
    # Compute Tests
    # =========================================================================

    def test_compute_display_name(self):
        """Test: computed display_name."""
        # Adjust field names to match your model
        expected = self.{{ model_var }}.name
        self.assertEqual(self.{{ model_var }}.display_name, expected)

    # =========================================================================
    # Constraint Tests
    # =========================================================================

    def test_constrains_name_required(self):
        """Test: name field is required — SQL constraint should fire."""
        from psycopg2 import IntegrityError

        with self.assertRaises((ValidationError, IntegrityError)):
            self.env["{{ model.name }}"].create({"name": False})

    # =========================================================================
    # Workflow / State Transition Tests
    # =========================================================================

    def test_action_confirm(self):
        """Test: confirm transitions state from draft to confirmed."""
        record = self.env["{{ model.name }}"].create({"name": "Confirm Test"})
        self.assertEqual(record.state, "draft")

        record.action_confirm()
        self.assertEqual(record.state, "confirmed")

    def test_action_cancel(self):
        """Test: cancel transitions state correctly."""
        record = self.env["{{ model.name }}"].create({"name": "Cancel Test"})
        record.action_confirm()
        record.action_cancel()
        self.assertEqual(record.state, "cancelled")

    def test_action_reset_to_draft(self):
        """Test: reset to draft from cancelled state."""
        record = self.env["{{ model.name }}"].create({"name": "Reset Test"})
        record.action_confirm()
        record.action_cancel()
        record.action_reset_to_draft()
        self.assertEqual(record.state, "draft")

    # =========================================================================
    # Form Simulation Tests (onchange)
    # =========================================================================

    def test_onchange_{{ trigger_field }}(self):
        """Test: onchange of {{ trigger_field }} fills {{ result_field }}."""
        form = Form(self.env["{{ model.name }}"])
        form.name = "Onchange Test"
        # form.{{ trigger_field }} = self.{{ related_object }}
        # self.assertEqual(form.{{ result_field }}, expected_value)
        record = form.save()
        self.assertTrue(record.exists())

    # =========================================================================
    # Security Tests
    # =========================================================================

    def test_access_user_group(self):
        """Test: user group can read/write/create but not delete."""
        user = self.env["res.users"].create({
            "name": "Test User",
            "login": "test_user_{{ model_underscore }}@example.com",
            "groups_id": [(4, self.env.ref("{{ module_name }}.group_{{ module_name }}_user").id)],
        })
        record_as_user = self.{{ model_var }}.with_user(user)
        # Should be able to read
        self.assertTrue(record_as_user.name)
        # Should NOT be able to delete
        with self.assertRaises(Exception):
            record_as_user.unlink()
