# Odoo UI Tour Test Runner (Python) — Odoo 16.0–19.0
# Replace all {{ placeholders }} with actual values.
#
# USAGE:
# 1. Place in {{ module_name }}/tests/test_ui_tour.py
# 2. Run with: odoo-bin -d <db> -i {{ module_name }} --test-enable --test-tags=post_install

from odoo.tests import HttpCase, tagged


@tagged('post_install', '-at_install')
class TestUiTour(HttpCase):

    def test_{{ tour_name }}_tour(self):
        """Run the {{ tour_name }} tour."""
        
        # 1. Prepare data needed for the tour (if any)
        # self.env['{{ target_model }}'].create({'name': 'Pre-existing Record'})
        
        # 2. Authenticate as the user who will run the tour
        # For backend tours, usually admin. For portal tours, a portal user.
        # self.authenticate('admin', 'admin')

        # 3. Start the tour
        # start_tour(start_url, tour_name, login='admin')
        self.start_tour("/web", "{{ tour_name }}", login="admin")
        
        # 4. Assert backend state changed as a result of the tour
        # record = self.env['{{ target_model }}'].search([('name', '=', 'My Test Record')])
        # self.assertTrue(record.exists(), "The record should have been created by the UI tour.")
