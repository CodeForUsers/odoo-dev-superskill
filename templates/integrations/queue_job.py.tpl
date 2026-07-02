# Queue Job Async Integration Template — Odoo 16.0-19.0
# Replace all {{ placeholders }} with actual values.
#
# REQUIRES: The 'queue_job' module from OCA (https://github.com/OCA/queue)
# Add "queue_job" to the "depends" list in __manifest__.py.
#
# USAGE:
# 1. Add `queue_job` decorator to the method you want to run asynchronously.
# 2. Call it using `.with_delay().method_name()` instead of `.method_name()`.

from odoo import models, fields, api
from odoo.addons.queue_job.job import queue_job

import logging
_logger = logging.getLogger(__name__)


class {{ ModelClassName }}(models.Model):
    _inherit = '{{ target_model }}'

    # Example: A method that takes a long time (e.g. sending API request)
    # We decorate it so it can be enqueued.
    @queue_job
    def _async_process_heavy_task(self):
        """Processes heavy task asynchronously.
        
        This method will be picked up by a worker thread in the background.
        """
        for record in self:
            try:
                # Do heavy lifting: external API call, massive calculation, etc.
                _logger.info("Processing async job for record %s", record.id)
                record.state = 'done'
            except Exception as e:
                _logger.error("Error processing record %s: %s", record.id, e)
                # In queue_job, raising an exception will mark the job as 'failed'
                # and it can be retried later.
                raise

    def action_trigger_async_job(self):
        """Action triggered by a user clicking a button in the UI."""
        for record in self:
            # We call the method using .with_delay()
            # This creates a queue.job record instead of executing immediately.
            # You can pass arguments like eta, priority, max_retries, channel.
            record.with_delay(
                priority=10, 
                description=f"Processing {record.name}"
            )._async_process_heavy_task()
            
        return {
            'type': 'ir.actions.client',
            'tag': 'display_notification',
            'params': {
                'title': 'Job Enqueued',
                'message': 'The task will be processed in the background.',
                'sticky': False,
            }
        }
