# HTTP Controller Template — Odoo 16.0–19.0 (OCA Standard)
# Replace all {{ placeholders }} with actual values.
#
# USAGE:
#   - Place this file in: {{ module_name }}/controllers/{{ controller_name }}.py
#   - Register in:        {{ module_name }}/controllers/__init__.py
#   - Register the controllers folder in:  {{ module_name }}/__init__.py
#
# SECURITY RULES:
#   - auth="user"   → Only authenticated backend users (session cookie)
#   - auth="public" → Anyone (portal + public), ideal for website pages
#   - auth="none"   → No authentication at all (use for webhooks, verify manually)
#   - Never expose sensitive data on auth="public" / auth="none" endpoints
#   - Use sudo() ONLY after verifying identity/token
#   - Add csrf=False ONLY on webhooks; always verify the payload signature

from odoo import http
from odoo.http import request

import json
import logging

_logger = logging.getLogger(__name__)


class {{ ControllerClassName }}(http.Controller):
    """{{ controller_description }}."""

    # =========================================================================
    # JSON API — authenticated (for backend / mobile apps)
    # =========================================================================

    @http.route(
        "/{{ module_name }}/api/v1/{{ resource_plural }}",
        type="json",
        auth="user",
        methods=["GET"],
    )
    def list_{{ resource_plural }}(self, domain=None, limit=80, offset=0, **kwargs):
        """Return a paginated list of records as JSON."""
        domain = domain or []
        records = request.env["{{ model.name }}"].search(
            domain,
            limit=limit,
            offset=offset,
        )
        return {
            "count": request.env["{{ model.name }}"].search_count(domain),
            "records": records.read(["name", "state"]),
        }

    @http.route(
        "/{{ module_name }}/api/v1/{{ resource_plural }}/<int:record_id>",
        type="json",
        auth="user",
        methods=["GET"],
    )
    def get_{{ resource }}(self, record_id, **kwargs):
        """Return a single record by ID."""
        record = request.env["{{ model.name }}"].browse(record_id)
        if not record.exists():
            return {"error": "Not found", "id": record_id}
        return record.read(["name", "state", "create_date"])[0]

    @http.route(
        "/{{ module_name }}/api/v1/{{ resource_plural }}",
        type="json",
        auth="user",
        methods=["POST"],
        csrf=False,  # CSRF handled via JSON token
    )
    def create_{{ resource }}(self, **kwargs):
        """Create a new record. Expects JSON body."""
        required_fields = ["name"]
        for field in required_fields:
            if field not in kwargs:
                return {"error": f"Missing required field: '{field}'"}

        record = request.env["{{ model.name }}"].create({
            "name": kwargs.get("name"),
            # Add more fields as needed
        })
        return {"id": record.id, "name": record.name}

    # =========================================================================
    # Webhook endpoint — no authentication (verify payload signature!)
    # =========================================================================

    @http.route(
        "/{{ module_name }}/webhook/{{ event_name }}",
        type="http",
        auth="none",
        methods=["POST"],
        csrf=False,
    )
    def webhook_{{ event_name }}(self, **kwargs):
        """Receive an external webhook event. Verifies HMAC signature."""
        try:
            raw_body = request.httprequest.get_data(as_text=True)
            signature = request.httprequest.headers.get("X-Webhook-Signature", "")

            if not self._verify_signature(raw_body, signature):
                _logger.warning("Webhook signature mismatch.")
                return request.make_response(
                    "Unauthorized", status=401,
                    headers=[("Content-Type", "text/plain")],
                )

            payload = json.loads(raw_body)
            _logger.info("Webhook received: %s", payload.get("event"))

            # Process the webhook in background (don't block the response)
            request.env["{{ model.name }}"].sudo()._process_webhook(payload)

            return request.make_response(
                '{"status": "ok"}',
                headers=[("Content-Type", "application/json")],
            )

        except Exception as e:
            _logger.exception("Error processing webhook: %s", e)
            return request.make_response(
                '{"status": "error"}', status=500,
                headers=[("Content-Type", "application/json")],
            )

    # =========================================================================
    # Public website page — renders a QWeb template
    # =========================================================================

    @http.route(
        "/{{ module_name }}/{{ resource_plural }}",
        type="http",
        auth="public",
        website=True,
    )
    def portal_{{ resource_plural }}_index(self, **kwargs):
        """Public-facing list page. Render a QWeb template."""
        records = request.env["{{ model.name }}"].sudo().search(
            [("state", "=", "published")],
            limit=20,
        )
        return request.render(
            "{{ module_name }}.portal_{{ resource_plural }}_page",
            {
                "records": records,
                "page_name": "{{ resource_plural }}",
            },
        )

    # =========================================================================
    # Private helpers
    # =========================================================================

    def _verify_signature(self, body, signature):
        """Verify HMAC-SHA256 signature from an external provider.

        Replace SECRET_TOKEN with the actual shared secret, stored
        ideally in an ir.config_parameter:
            request.env["ir.config_parameter"].sudo().get_param(
                "{{ module_name }}.webhook_secret"
            )
        """
        import hashlib
        import hmac

        secret = (
            request.env["ir.config_parameter"]
            .sudo()
            .get_param("{{ module_name }}.webhook_secret", default="")
        )
        expected = hmac.new(
            secret.encode(),
            body.encode(),
            hashlib.sha256,
        ).hexdigest()
        return hmac.compare_digest(f"sha256={expected}", signature)
