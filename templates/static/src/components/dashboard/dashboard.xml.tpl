<?xml version="1.0" encoding="UTF-8" ?>
<!-- Dashboard Client Action Component (XML) — Odoo 16.0–19.0 -->
<!-- Replace all {{ placeholders }} with actual values. -->
<templates xml:space="preserve">

    <t t-name="{{ module_name }}.{{ DashboardClassName }}">
        <div class="o_content o_{{ module_name }}_dashboard_container p-4 bg-light w-100 h-100 overflow-auto">
            
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h1 class="text-primary fw-bold">My Dashboard</h1>
                <button class="btn btn-outline-primary" t-on-click="loadData">
                    <i class="fa fa-refresh me-2"/>Refresh
                </button>
            </div>

            <!-- Loading Skeleton -->
            <t t-if="state.isLoading">
                <div class="d-flex justify-content-center mt-5">
                    <div class="spinner-border text-primary" role="status">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                </div>
            </t>

            <!-- Dashboard Content -->
            <t t-else="">
                <!-- KPI Cards Row -->
                <div class="row g-4 mb-4">
                    <!-- KPI 1 -->
                    <div class="col-md-6 col-lg-3">
                        <div class="card shadow-sm border-0 rounded-3 dashboard-card h-100">
                            <div class="card-body">
                                <div class="d-flex justify-content-between align-items-center">
                                    <div>
                                        <h6 class="text-muted text-uppercase fw-semibold mb-2">Total Orders</h6>
                                        <h2 class="mb-0 fw-bold text-dark" t-esc="state.kpi_orders"/>
                                    </div>
                                    <div class="bg-primary bg-opacity-10 p-3 rounded-circle text-primary">
                                        <i class="fa fa-shopping-cart fa-2x"/>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- KPI 2 -->
                    <div class="col-md-6 col-lg-3">
                        <div class="card shadow-sm border-0 rounded-3 dashboard-card h-100">
                            <div class="card-body">
                                <div class="d-flex justify-content-between align-items-center">
                                    <div>
                                        <h6 class="text-muted text-uppercase fw-semibold mb-2">Total Revenue</h6>
                                        <h2 class="mb-0 fw-bold text-success">
                                            $<t t-esc="state.kpi_revenue.toFixed(2)"/>
                                        </h2>
                                    </div>
                                    <div class="bg-success bg-opacity-10 p-3 rounded-circle text-success">
                                        <i class="fa fa-money fa-2x"/>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Recent Items Table -->
                <div class="card shadow-sm border-0 rounded-3">
                    <div class="card-header bg-white border-bottom-0 pt-4 pb-0">
                        <h5 class="fw-bold text-dark mb-0">Recent Orders</h5>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-hover align-middle">
                                <thead class="table-light">
                                    <tr>
                                        <th>Reference</th>
                                        <th>Status</th>
                                        <th class="text-end">Amount</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <t t-if="state.recent_items.length === 0">
                                        <tr><td colspan="3" class="text-center text-muted py-4">No recent items found.</td></tr>
                                    </t>
                                    <t t-foreach="state.recent_items" t-as="item" t-key="item.id">
                                        <tr class="cursor-pointer" t-on-click="() => this.openRecord(item.id)">
                                            <td class="fw-semibold text-primary"><t t-esc="item.name"/></td>
                                            <td>
                                                <span class="badge rounded-pill"
                                                      t-att-class="item.state === 'sale' ? 'text-bg-success' : 'text-bg-secondary'"
                                                      t-esc="item.state"/>
                                            </td>
                                            <td class="text-end fw-bold">$<t t-esc="item.amount_total.toFixed(2)"/></td>
                                        </tr>
                                    </t>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </t>

        </div>
    </t>

</templates>
