# Customer Portal Controller Template — Odoo 16.0–19.0
# Replace all {{ placeholders }} with actual values.
#
# USAGE:
#   - Place in: {{ module_name }}/controllers/portal.py
#   - Import in: {{ module_name }}/controllers/__init__.py

from odoo import http
from odoo.exceptions import AccessError, MissingError
from odoo.http import request
from odoo.addons.portal.controllers.portal import CustomerPortal, pager as portal_pager


class {{ ModuleName }}Portal(CustomerPortal):

    def _prepare_home_portal_values(self, counters):
        """Add the counter to the portal home page."""
        values = super()._prepare_home_portal_values(counters)
        
        # '{{ record_plural }}' is just an identifier we use
        if '{{ record_plural }}' in counters:
            domain = self._prepare_{{ record_plural }}_domain()
            # Count records user has access to
            count = request.env['{{ target_model }}'].search_count(domain)
            values['{{ record_plural }}_count'] = count
            
        return values

    def _prepare_{{ record_plural }}_domain(self):
        """Base domain for security/filtering."""
        # Typically filter by partner or just rely on standard Odoo security (ir.rule)
        # If ir.rule exists, you can return []
        return []

    @http.route(['/my/{{ url_path }}', '/my/{{ url_path }}/page/<int:page>'], type='http', auth="user", website=True)
    def portal_my_{{ record_plural }}(self, page=1, date_begin=None, date_end=None, sortby=None, **kw):
        """Route to display the list of records."""
        values = self._prepare_portal_layout_values()
        {{ Model }} = request.env['{{ target_model }}']

        domain = self._prepare_{{ record_plural }}_domain()

        # Date filtering
        if date_begin and date_end:
            domain += [('create_date', '>', date_begin), ('create_date', '<=', date_end)]

        # Sorting definitions
        searchbar_sortings = {
            'date': {'label': 'Date', 'order': 'create_date desc'},
            'name': {'label': 'Reference', 'order': 'name'},
            'state': {'label': 'Status', 'order': 'state'},
        }
        if not sortby:
            sortby = 'date'
        sort_order = searchbar_sortings[sortby]['order']

        # Count total records for pager
        total_count = {{ Model }}.search_count(domain)
        
        # Prepare pager
        pager = portal_pager(
            url="/my/{{ url_path }}",
            url_args={'date_begin': date_begin, 'date_end': date_end, 'sortby': sortby},
            total=total_count,
            page=page,
            step=self._items_per_page
        )
        
        # Search records
        records = {{ Model }}.search(domain, order=sort_order, limit=self._items_per_page, offset=pager['offset'])
        
        # Provide variables to QWeb template
        values.update({
            '{{ record_plural }}': records,
            'page_name': '{{ record_plural }}',
            'pager': pager,
            'default_url': '/my/{{ url_path }}',
            'searchbar_sortings': searchbar_sortings,
            'sortby': sortby,
        })
        
        return request.render("{{ module_name }}.portal_my_{{ record_plural }}", values)

    @http.route(['/my/{{ url_path }}/<int:record_id>'], type='http', auth="public", website=True)
    def portal_my_{{ record_singular }}_detail(self, record_id, access_token=None, **kw):
        """Route to display a single record."""
        try:
            # check_access_rights handles security based on access_token or login
            record_sudo = self._document_check_access('{{ target_model }}', record_id, access_token)
        except (AccessError, MissingError):
            return request.redirect('/my')

        values = self._{{ record_singular }}_get_page_view_values(record_sudo, access_token, **kw)
        return request.render("{{ module_name }}.portal_my_{{ record_singular }}", values)

    def _{{ record_singular }}_get_page_view_values(self, record, access_token, **kwargs):
        """Helper to prepare values for the detail view."""
        values = {
            'page_name': '{{ record_singular }}',
            'record': record,
        }
        return self._get_page_view_values(record, access_token, values, 'my_{{ record_plural }}_history', False, **kwargs)
