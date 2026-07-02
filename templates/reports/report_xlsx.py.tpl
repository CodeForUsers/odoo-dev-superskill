# Excel Report Logic (report_xlsx) — Odoo 16.0–19.0
# Replace all {{ placeholders }} with actual values.
#
# USAGE:
# 1. Place in {{ module_name }}/reports/report_xlsx.py
# 2. Add to __init__.py
# 3. Add "report_xlsx" to the "depends" list in __manifest__.py

from odoo import models


class {{ ReportClassName }}Xlsx(models.AbstractModel):
    # The _name MUST match the report_name in the ir.actions.report XML record
    # prefixed by 'report.'
    _name = 'report.{{ module_name }}.report_{{ report_name }}_xlsx'
    _description = '{{ Report Description }} Excel'
    # Must inherit from report.report_xlsx.abstract
    _inherit = 'report.report_xlsx.abstract'

    def generate_xlsx_report(self, workbook, data, records):
        """Generates the Excel file.
        
        Args:
            workbook: xlsxwriter Workbook object
            data: dictionary of parameters passed from a wizard (if any)
            records: recordset of the model being printed
        """
        # 1. Add a worksheet
        sheet = workbook.add_worksheet('{{ Sheet Name }}')

        # 2. Define formats (xlsxwriter formats)
        format_title = workbook.add_format({
            'font_size': 14, 
            'bold': True, 
            'align': 'center', 
            'valign': 'vcenter'
        })
        format_header = workbook.add_format({
            'bold': True, 
            'bg_color': '#D3D3D3', 
            'border': 1
        })
        format_cell = workbook.add_format({'border': 1})
        format_currency = workbook.add_format({'border': 1, 'num_format': '#,##0.00'})

        # 3. Set column widths
        sheet.set_column(0, 0, 15)  # Col A: width 15
        sheet.set_column(1, 1, 30)  # Col B: width 30
        sheet.set_column(2, 3, 15)  # Col C-D: width 15

        # 4. Write data
        row = 0
        for record in records:
            # Title spanning multiple columns
            sheet.merge_range(row, 0, row, 3, f"Report for {record.name}", format_title)
            row += 2

            # Table Headers
            headers = ['Reference', 'Date', 'Status', 'Total']
            for col, head in enumerate(headers):
                sheet.write(row, col, head, format_header)
            row += 1

            # Table Rows (example assuming record has line_ids)
            for line in record.line_ids:
                sheet.write(row, 0, line.name or '', format_cell)
                # Dates must be converted to string or Excel date formats
                sheet.write(row, 1, str(line.create_date)[:10] if line.create_date else '', format_cell)
                sheet.write(row, 2, dict(line._fields['state'].selection).get(line.state, ''), format_cell)
                sheet.write(row, 3, line.price_subtotal or 0.0, format_currency)
                row += 1

            row += 2  # Space between records if printing multiple
