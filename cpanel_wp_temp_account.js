// WHM/cPanel WP Temporary Account Plugin - Universal Version

// Global CSRF token
let csrfToken = null;

// Helper function to add cpuser parameter for WHM context
function addCpuserParam(data) {
    const cpuserEl = document.getElementById('cpuser');
    if (cpuserEl && cpuserEl.value) {
        data.cpuser = cpuserEl.value;
    }
    return data;
}

$(document).ready(function() {
    // Initialize CSRF token
    getCSRFToken().then(() => {
        loadDashboard();
        loadWordPressSites();
        loadActiveAccounts();
        loadSystemInfo();
        loadRecentActivity();
    });

    // Form submission
    $('#createAccountForm').on('submit', function(e) {
        e.preventDefault();
        createTempAccount();
    });

    // Button handlers
    $('#refreshAccounts').on('click', loadActiveAccounts);
    $('#cleanupExpired').on('click', cleanupExpiredAccounts);
    $('#toggleSystemInfo').on('click', toggleSystemInfo);

    // Filter handlers
    $('#accountSearch').on('input', filterAccounts);
    $('#statusFilter').on('change', filterAccounts);
    $('#siteFilter').on('change', filterAccounts);

    // Modal close handler
    $('.cpanel-modal-close').on('click', closeModal);
    $(window).on('click', function(e) {
        if (e.target.id === 'accountModal') {
            closeModal();
        }
    });

    // Auto-refresh every 30 seconds
    setInterval(function() {
        loadActiveAccounts(true); // Silent refresh
        loadDashboard(true); // Silent dashboard refresh
        loadRecentActivity(true); // Silent activity refresh
    }, 30000);

    // Refresh CSRF token every 45 minutes
    setInterval(function() {
        getCSRFToken();
    }, 45 * 60 * 1000);
});

// Security: HTML escaping function
function escapeHtml(unsafe) {
    if (unsafe === null || unsafe === undefined) return '';
    return String(unsafe)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

// Security: URL validation
function isValidUrl(string) {
    try {
        const url = new URL(string);
        return url.protocol === "http:" || url.protocol === "https:";
    } catch (_) {
        return false;
    }
}

// Security: Sanitize URL
function sanitizeUrl(url) {
    if (!url) return '#';
    if (!isValidUrl(url)) return '#';
    // Remove javascript: and data: protocols
    if (url.toLowerCase().startsWith('javascript:') ||
        url.toLowerCase().startsWith('data:')) {
        return '#';
    }
    return url;
}

// Get CSRF token
function getCSRFToken() {
    return $.ajax({
        url: 'cpanel_wp_temp_account.pl',
        method: 'POST',
        data: addCpuserParam({ action: 'get_csrf_token' }),
        dataType: 'json'
    }).done(function(response) {
        if (response.success && response.data.csrf_token) {
            csrfToken = response.data.csrf_token;
        } else {
            showError('Failed to get CSRF token');
        }
    }).fail(function() {
        showError('Failed to get CSRF token');
    });
}

// Add CSRF token to all requests
function ajaxWithCSRF(options) {
    if (!options.data) {
        options.data = {};
    }
    options.data.csrf_token = csrfToken;
    return $.ajax(options);
}

function loadSystemInfo() {
    $.ajax({
        url: 'cpanel_wp_temp_account.pl',
        method: 'POST',
        data: addCpuserParam({ action: 'get_system_info' }),
        dataType: 'json',
        success: function(response) {
            if (response.success) {
                const info = response.data;
                const html = `
                    <div class="system-info">
                        <p><strong>Server:</strong> ${escapeHtml(info.server_name)}:${escapeHtml(info.server_port)}</p>
                        <p><strong>Interface:</strong> ${info.is_whm ? 'WHM' : 'cPanel'}</p>
                        <p><strong>User:</strong> ${escapeHtml(info.user)}</p>
                        <p><strong>Session:</strong> ${escapeHtml(info.session_token)}</p>
                        <p><strong>Security Features:</strong></p>
                        <ul>
                            <li>CSRF Protection: ${info.security_features.csrf_protection ? '✅' : '❌'}</li>
                            <li>Input Validation: ${info.security_features.input_validation ? '✅' : '❌'}</li>
                            <li>Encrypted Storage: ${info.security_features.encrypted_storage ? '✅' : '❌'}</li>
                        </ul>
                    </div>
                `;
                $('#systemDetails').html(html);
            }
        }
    });
}

function toggleSystemInfo() {
    $('#systemInfo').toggle();
}

// Dashboard Functions

function loadDashboard(silent = false) {
    // Load statistics
    $.ajax({
        url: 'cpanel_wp_temp_account.pl',
        method: 'POST',
        data: addCpuserParam({ action: 'get_statistics' }),
        dataType: 'json',
        success: function(response) {
            if (response.success) {
                updateDashboardCards(response.data);
                updateSiteChart(response.data.accounts_by_site);
            }
        },
        error: function() {
            if (!silent) showError('Failed to load dashboard statistics');
        }
    });

    // Load alerts
    $.ajax({
        url: 'cpanel_wp_temp_account.pl',
        method: 'POST',
        data: addCpuserParam({ action: 'get_alerts' }),
        dataType: 'json',
        success: function(response) {
            if (response.success) {
                updateAlerts(response.data.alerts);
            }
        },
        error: function() {
            if (!silent) showError('Failed to load alerts');
        }
    });
}

function updateDashboardCards(stats) {
    // Update active accounts card
    $('#activeCount').text(stats.active_accounts);
    const activeCard = $('#activeAccountsCard');

    if (stats.active_accounts > 20) {
        $('#activeStatus').text('Critical Level').addClass('status-danger');
        activeCard.addClass('card-danger');
    } else if (stats.active_accounts > 10) {
        $('#activeStatus').text('High Usage').addClass('status-warning');
        activeCard.addClass('card-warning');
    } else {
        $('#activeStatus').text('Normal').addClass('status-ok');
        activeCard.addClass('card-ok');
    }

    // Update other cards
    $('#expiredTodayCount').text(stats.expired_today);
    $('#createdTodayCount').text(stats.created_today);

    // Rate limit status
    const remaining = 10 - stats.created_today; // Assuming 10 per day limit
    if (remaining <= 2) {
        $('#rateLimitStatus').text(`${remaining} remaining`).addClass('status-warning');
    } else {
        $('#rateLimitStatus').text(`${remaining} remaining`).addClass('status-ok');
    }
}

function updateAlerts(alerts) {
    $('#alertsCount').text(alerts.length);

    if (alerts.length === 0) {
        $('#alertsStatus').text('All Clear').removeClass('status-warning status-danger').addClass('status-ok');
        $('#alertsSection').hide();
        $('#alertsCard').removeClass('card-warning card-danger').addClass('card-ok');
    } else {
        const hasErrors = alerts.some(alert => alert.level === 'danger');
        const hasWarnings = alerts.some(alert => alert.level === 'warning');

        if (hasErrors) {
            $('#alertsStatus').text('Critical Issues').removeClass('status-ok status-warning').addClass('status-danger');
            $('#alertsCard').removeClass('card-ok card-warning').addClass('card-danger');
        } else if (hasWarnings) {
            $('#alertsStatus').text('Warnings').removeClass('status-ok status-danger').addClass('status-warning');
            $('#alertsCard').removeClass('card-ok card-danger').addClass('card-warning');
        } else {
            $('#alertsStatus').text('Info').removeClass('status-warning status-danger').addClass('status-ok');
            $('#alertsCard').removeClass('card-warning card-danger').addClass('card-ok');
        }

        displayAlerts(alerts);
        $('#alertsSection').show();
    }
}

function displayAlerts(alerts) {
    let alertsHtml = '';

    alerts.forEach(function(alert) {
        const iconMap = {
            'danger': '🚨',
            'warning': '⚠️',
            'info': 'ℹ️'
        };

        alertsHtml += `
            <div class="alert alert-${alert.level}">
                <span class="alert-icon">${iconMap[alert.level]}</span>
                <span class="alert-message">${escapeHtml(alert.message)}</span>
                ${alert.action ? `<button class="alert-action" onclick="handleAlertAction('${alert.action}')">${getActionLabel(alert.action)}</button>` : ''}
            </div>
        `;
    });

    $('#alertsList').html(alertsHtml);
}

function getActionLabel(action) {
    const labels = {
        'cleanup_expired': 'Clean Up Now',
        'review_accounts': 'Review Accounts',
        'check_cron': 'Check Cron Jobs'
    };
    return labels[action] || 'Take Action';
}

function handleAlertAction(action) {
    switch(action) {
        case 'cleanup_expired':
            cleanupExpiredAccounts();
            break;
        case 'review_accounts':
            // Scroll to accounts section
            $('#accountsList')[0].scrollIntoView({ behavior: 'smooth' });
            break;
        case 'check_cron':
            showWarning('Please check that the cron job is properly configured for automatic cleanup.');
            break;
    }
}

function updateSiteChart(accountsBySite) {
    if (!accountsBySite || Object.keys(accountsBySite).length === 0) {
        $('#siteChart').html('<div class="chart-placeholder">No active accounts found</div>');
        return;
    }

    let chartHtml = '<div class="site-stats">';

    // Sort sites by account count
    const sortedSites = Object.entries(accountsBySite)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 10); // Top 10 sites

    const maxCount = Math.max(...Object.values(accountsBySite));

    sortedSites.forEach(([site, count]) => {
        const percentage = (count / maxCount) * 100;
        chartHtml += `
            <div class="site-stat-row">
                <div class="site-name">${escapeHtml(site)}</div>
                <div class="site-bar">
                    <div class="site-bar-fill" style="width: ${percentage}%"></div>
                </div>
                <div class="site-count">${count}</div>
            </div>
        `;
    });

    chartHtml += '</div>';
    $('#siteChart').html(chartHtml);
}

function loadRecentActivity(silent = false) {
    $.ajax({
        url: 'cpanel_wp_temp_account.pl',
        method: 'POST',
        data: addCpuserParam({
            action: 'get_activity',
            limit: 20
        }),
        dataType: 'json',
        success: function(response) {
            if (response.success) {
                displayRecentActivity(response.data.activity);
            }
        },
        error: function() {
            if (!silent) {
                $('#activityFeed').html('<div class="activity-error">Failed to load activity</div>');
            }
        }
    });
}

function displayRecentActivity(activities) {
    if (!activities || activities.length === 0) {
        $('#activityFeed').html('<div class="activity-empty">No recent activity</div>');
        return;
    }

    let activityHtml = '';

    activities.forEach(function(activity) {
        const timeAgo = getTimeAgo(activity.timestamp);
        const icon = getActivityIcon(activity.type);

        activityHtml += `
            <div class="activity-item">
                <div class="activity-icon">${icon}</div>
                <div class="activity-content">
                    <div class="activity-description">${escapeHtml(activity.details)}</div>
                    <div class="activity-meta">
                        <span class="activity-user">${escapeHtml(activity.user)}</span>
                        <span class="activity-time">${timeAgo}</span>
                        ${activity.ip !== 'unknown' ? `<span class="activity-ip">${escapeHtml(activity.ip)}</span>` : ''}
                    </div>
                </div>
            </div>
        `;
    });

    $('#activityFeed').html(activityHtml);
}

function getActivityIcon(type) {
    const icons = {
        'account_created': '✨',
        'account_deleted': '🗑️',
        'account_cleaned': '🧹',
        'cleanup_expired': '🔄',
        'security_event': '🚨',
        'suspicious_behavior': '⚠️',
        'rate_limit_exceeded': '🚫',
        'honeypot_triggered': '🍯'
    };
    return icons[type] || '📝';
}

function getTimeAgo(timestamp) {
    const now = Math.floor(Date.now() / 1000);
    const diff = now - timestamp;

    if (diff < 60) return 'Just now';
    if (diff < 3600) return Math.floor(diff / 60) + 'm ago';
    if (diff < 86400) return Math.floor(diff / 3600) + 'h ago';
    if (diff < 604800) return Math.floor(diff / 86400) + 'd ago';
    return Math.floor(diff / 604800) + 'w ago';
}

// Table filtering and sorting functions

function filterAccounts() {
    const searchTerm = $('#accountSearch').val().toLowerCase();
    const statusFilter = $('#statusFilter').val();
    const siteFilter = $('#siteFilter').val();

    let filteredAccounts = allAccounts.filter(function(account) {
        // Search filter
        const searchMatch = !searchTerm ||
            account.domain.toLowerCase().includes(searchTerm) ||
            account.username.toLowerCase().includes(searchTerm) ||
            (account.created_by && account.created_by.toLowerCase().includes(searchTerm));

        // Status filter
        const timeLeft = account.time_remaining || '';
        const isExpiring = timeLeft.includes('hour') && parseInt(timeLeft) < 2;

        let statusMatch = true;
        if (statusFilter === 'active') {
            statusMatch = !isExpiring;
        } else if (statusFilter === 'expiring') {
            statusMatch = isExpiring;
        }

        // Site filter
        const siteMatch = !siteFilter || account.domain === siteFilter;

        return searchMatch && statusMatch && siteMatch;
    });

    // Update filter count
    if (filteredAccounts.length !== allAccounts.length) {
        $('#filterCount').text(`(${filteredAccounts.length} shown)`).show();
    } else {
        $('#filterCount').hide();
    }

    renderAccountsTable(filteredAccounts);
}

let currentSort = { field: null, direction: 'asc' };

function sortTable(field) {
    // Toggle direction if same field
    if (currentSort.field === field) {
        currentSort.direction = currentSort.direction === 'asc' ? 'desc' : 'asc';
    } else {
        currentSort.field = field;
        currentSort.direction = 'asc';
    }

    // Update sort indicators
    $('.sort-indicator').removeClass('sort-asc sort-desc');
    $(`[data-sort="${field}"] .sort-indicator`).addClass(`sort-${currentSort.direction}`);

    // Sort the current filtered accounts
    let accountsToSort = getCurrentFilteredAccounts();

    accountsToSort.sort((a, b) => {
        let aVal, bVal;

        switch (field) {
            case 'domain':
                aVal = a.domain.toLowerCase();
                bVal = b.domain.toLowerCase();
                break;
            case 'username':
                aVal = a.username.toLowerCase();
                bVal = b.username.toLowerCase();
                break;
            case 'created':
                aVal = a.expiry_timestamp - (a.hours * 3600); // Creation timestamp
                bVal = b.expiry_timestamp - (b.hours * 3600);
                break;
            case 'expires':
                aVal = a.expiry_timestamp;
                bVal = b.expiry_timestamp;
                break;
            case 'status':
                const aExpiring = a.time_remaining && a.time_remaining.includes('hour') && parseInt(a.time_remaining) < 2;
                const bExpiring = b.time_remaining && b.time_remaining.includes('hour') && parseInt(b.time_remaining) < 2;
                aVal = aExpiring ? 1 : 0;
                bVal = bExpiring ? 1 : 0;
                break;
            default:
                return 0;
        }

        if (aVal < bVal) return currentSort.direction === 'asc' ? -1 : 1;
        if (aVal > bVal) return currentSort.direction === 'asc' ? 1 : -1;
        return 0;
    });

    renderAccountsTable(accountsToSort);
}

function getCurrentFilteredAccounts() {
    const searchTerm = $('#accountSearch').val().toLowerCase();
    const statusFilter = $('#statusFilter').val();
    const siteFilter = $('#siteFilter').val();

    return allAccounts.filter(function(account) {
        const searchMatch = !searchTerm ||
            account.domain.toLowerCase().includes(searchTerm) ||
            account.username.toLowerCase().includes(searchTerm) ||
            (account.created_by && account.created_by.toLowerCase().includes(searchTerm));

        const timeLeft = account.time_remaining || '';
        const isExpiring = timeLeft.includes('hour') && parseInt(timeLeft) < 2;

        let statusMatch = true;
        if (statusFilter === 'active') {
            statusMatch = !isExpiring;
        } else if (statusFilter === 'expiring') {
            statusMatch = isExpiring;
        }

        const siteMatch = !siteFilter || account.domain === siteFilter;

        return searchMatch && statusMatch && siteMatch;
    });
}

function updateSiteFilter(accounts) {
    const siteFilter = $('#siteFilter');
    const currentValue = siteFilter.val();

    // Get unique sites
    const sites = [...new Set(accounts.map(account => account.domain))].sort();

    siteFilter.empty();
    siteFilter.append('<option value="">All Sites</option>');

    sites.forEach(site => {
        siteFilter.append(`<option value="${escapeHtml(site)}">${escapeHtml(site)}</option>`);
    });

    // Restore previous selection if it still exists
    if (currentValue && sites.includes(currentValue)) {
        siteFilter.val(currentValue);
    }
}

function loadWordPressSites() {
    showLoading('Loading WordPress sites...');

    $.ajax({
        url: 'cpanel_wp_temp_account.pl',
        method: 'POST',
        data: addCpuserParam({ action: 'get_wp_sites' }),
        dataType: 'json',
        success: function(response) {
            hideLoading();
            if (response.success) {
                populateWordPressSites(response.data.sites);
            } else {
                showError('Failed to load WordPress sites: ' + escapeHtml(response.error));
            }
        },
        error: function(xhr, status, error) {
            hideLoading();
            showError('Network error while loading WordPress sites: ' + escapeHtml(error));
        }
    });
}

function populateWordPressSites(sites) {
    const select = $('#wpSite');
    select.empty();

    if (!sites || sites.length === 0) {
        select.append('<option value="">No WordPress sites found</option>');
        select.prop('disabled', true);
        return;
    }

    select.prop('disabled', false);
    select.append('<option value="">Select a WordPress site...</option>');

    sites.forEach(function(site) {
        const domain = escapeHtml(site.domain || 'Unknown');
        const path = site.path !== '/' ? escapeHtml(site.path) : '';
        const version = escapeHtml(site.version || 'Unknown');
        const detectionMethod = site.detection_method || 'unknown';

        // Add detection method indicator
        let methodIcon = '';
        let methodTooltip = '';
        if (detectionMethod === 'wp_toolkit') {
            methodIcon = ' 🛠️';
            methodTooltip = 'Managed by WP Toolkit';
        } else if (detectionMethod === 'direct_scan') {
            methodIcon = ' 🔍';
            methodTooltip = 'Direct database access';
        }

        const displayText = `${domain}${path} (v${version})${methodIcon}`;
        const url = escapeHtml(site.url);
        const id = escapeHtml(site.id);

        const option = $('<option></option>')
            .attr('value', site.domain)
            .attr('data-url', url)
            .attr('data-id', id)
            .attr('data-detection-method', detectionMethod)
            .attr('title', methodTooltip)
            .text(displayText);

        select.append(option);
    });
}

function createTempAccount() {
    const domain = $('#wpSite').val();
    const hours = $('#expiryHours').val();

    if (!domain) {
        showError('Please select a WordPress site');
        return;
    }

    // Validate hours
    const hoursInt = parseInt(hours);
    if (isNaN(hoursInt) || hoursInt < 1 || hoursInt > 168) {
        showError('Invalid expiration time');
        return;
    }

    showLoading('Creating temporary account...');

    ajaxWithCSRF({
        url: 'cpanel_wp_temp_account.pl',
        method: 'POST',
        data: addCpuserParam({
            action: 'create_temp_account',
            domain: domain,
            hours: hoursInt
        }),
        dataType: 'json',
        success: function(response) {
            hideLoading();
            if (response.success) {
                showAccountCreated(response.data);
                loadActiveAccounts();
                loadDashboard(true); // Refresh dashboard
                loadRecentActivity(true); // Refresh activity
                $('#createAccountForm')[0].reset();
                $('#wpSite').val('');
            } else {
                showError('Failed to create account: ' + escapeHtml(response.error));
            }
        },
        error: function(xhr, status, error) {
            hideLoading();
            showError('Network error while creating account: ' + escapeHtml(error));
        }
    });
}

function showAccountCreated(accountData) {
    const domain = escapeHtml(accountData.domain);
    const username = escapeHtml(accountData.username);
    const password = escapeHtml(accountData.password);
    const email = escapeHtml(accountData.email);
    const expires = escapeHtml(accountData.expires);
    const loginUrl = sanitizeUrl(accountData.login_url);
    const creationMethod = accountData.creation_method || 'unknown';

    // Format creation method display
    let methodDisplay = '';
    let methodClass = '';
    if (creationMethod === 'wp_toolkit') {
        methodDisplay = '🛠️ WP Toolkit';
        methodClass = 'method-toolkit';
    } else if (creationMethod === 'direct_db') {
        methodDisplay = '🔍 Direct Database';
        methodClass = 'method-direct';
    } else {
        methodDisplay = 'Unknown';
        methodClass = 'method-unknown';
    }

    const detailsHtml = `
        <div class="account-details">
            <div class="detail-row">
                <strong>Domain:</strong> ${domain}
            </div>
            <div class="detail-row">
                <strong>Username:</strong>
                <span class="credential" id="newUsername">${username}</span>
                <button class="copy-btn" data-copy="${username}">Copy</button>
            </div>
            <div class="detail-row">
                <strong>Password:</strong>
                <span class="credential" id="newPassword">${password}</span>
                <button class="copy-btn" data-copy="${password}">Copy</button>
            </div>
            <div class="detail-row">
                <strong>Email:</strong> ${email}
            </div>
            <div class="detail-row">
                <strong>Expires:</strong> ${expires}
            </div>
            <div class="detail-row">
                <strong>Creation Method:</strong>
                <span class="creation-method ${methodClass}">${methodDisplay}</span>
            </div>
            <div class="detail-row">
                <strong>Login URL:</strong>
                <a href="${loginUrl}" target="_blank" rel="noopener noreferrer" class="cpanel-link">
                    ${escapeHtml(loginUrl)}
                </a>
                <button class="copy-btn" data-copy="${loginUrl}">Copy</button>
            </div>
        </div>
        <div class="cpanel-notice cpanel-notice-warning">
            <strong>Important:</strong> Save these credentials now! They will not be shown again.
        </div>
    `;

    $('#accountDetails').html(detailsHtml);
    $('#resultSection').show();

    // Attach copy handlers
    $('#accountDetails .copy-btn').on('click', function() {
        copyToClipboard($(this).data('copy'));
    });

    // Scroll to results
    $('#resultSection')[0].scrollIntoView({ behavior: 'smooth' });

    // Auto-hide after 30 seconds
    setTimeout(function() {
        $('#resultSection').fadeOut();
    }, 30000);
}

function loadActiveAccounts(silent = false) {
    if (!silent) {
        showLoading('Loading active accounts...');
    }

    $.ajax({
        url: 'cpanel_wp_temp_account.pl',
        method: 'POST',
        data: addCpuserParam({ action: 'list_temp_accounts' }),
        dataType: 'json',
        success: function(response) {
            if (!silent) hideLoading();
            if (response.success) {
                displayActiveAccounts(response.data.accounts);
            } else {
                if (!silent) showError('Failed to load accounts: ' + escapeHtml(response.error));
            }
        },
        error: function(xhr, status, error) {
            if (!silent) {
                hideLoading();
                showError('Network error while loading accounts: ' + escapeHtml(error));
            }
        }
    });
}

// Global variable to store accounts for filtering
let allAccounts = [];

function displayActiveAccounts(accounts) {
    const container = $('#accountsList');
    allAccounts = accounts || [];

    if (!accounts || accounts.length === 0) {
        container.html('<p class="cpanel-notice">No active temporary accounts found.</p>');
        updateSiteFilter([]);
        return;
    }

    // Update site filter dropdown
    updateSiteFilter(accounts);

    let tableHtml = `
        <div class="table-info">
            <span id="accountCount">${accounts.length} accounts</span>
            <span id="filterCount" style="display:none;"></span>
        </div>
        <table class="cpanel-table sortable-table">
            <thead>
                <tr>
                    <th class="sortable" data-sort="domain">Domain <span class="sort-indicator"></span></th>
                    <th class="sortable" data-sort="username">Username <span class="sort-indicator"></span></th>
                    <th class="sortable" data-sort="created">Created <span class="sort-indicator"></span></th>
                    <th class="sortable" data-sort="expires">Expires <span class="sort-indicator"></span></th>
                    <th class="sortable" data-sort="status">Status <span class="sort-indicator"></span></th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody id="accountsTableBody">
            </tbody>
        </table>
    `;

    container.html(tableHtml);

    // Add sorting handlers
    $('.sortable').on('click', function() {
        const sortField = $(this).data('sort');
        sortTable(sortField);
    });

    renderAccountsTable(accounts);
}

function renderAccountsTable(accounts) {
    const tbody = $('#accountsTableBody');

    tbody.empty();

    accounts.forEach(function(account) {
        const domain = escapeHtml(account.domain);
        const username = escapeHtml(account.username);
        const created = escapeHtml(account.created);
        const createdBy = escapeHtml(account.created_by || 'unknown');
        const expires = escapeHtml(account.expires);
        const timeLeft = escapeHtml(account.time_remaining || 'Unknown');
        const url = sanitizeUrl(account.url || 'https://' + account.domain);

        const isExpiring = timeLeft.includes('hour') && parseInt(timeLeft) < 2;
        const statusClass = isExpiring ? 'status-warning' : 'status-ok';
        const statusText = isExpiring ? 'Expiring Soon' : 'Active';

        const row = $('<tr></tr>');

        row.append(`
            <td>
                <strong>${domain}</strong>
                <br><small><a href="${url}" target="_blank" rel="noopener noreferrer" class="cpanel-link">${escapeHtml(url)}</a></small>
            </td>
            <td><code>${username}</code></td>
            <td>
                ${created}
                <br><small>by ${createdBy}</small>
            </td>
            <td>
                ${expires}
                <br><small class="${statusClass}">${timeLeft}</small>
            </td>
            <td>
                <span class="status-badge ${statusClass}">${statusText}</span>
            </td>
            <td>
                <div class="action-buttons">
                    <button class="cpanel-button cpanel-button-small view-btn"
                            data-domain="${domain}"
                            data-username="${username}"
                            data-url="${url}">
                        View
                    </button>
                    <button class="cpanel-button cpanel-button-small cpanel-button-danger delete-btn"
                            data-domain="${domain}"
                            data-username="${username}">
                        Delete
                    </button>
                </div>
            </td>
        `);

        tbody.append(row);
    });

    // Attach event handlers
    $('.view-btn').on('click', function() {
        const domain = $(this).data('domain');
        const username = $(this).data('username');
        const url = $(this).data('url');
        showAccountDetails(domain, username, '', url);
    });

    $('.delete-btn').on('click', function() {
        const domain = $(this).data('domain');
        const username = $(this).data('username');
        deleteAccount(domain, username);
    });
}

function cleanupExpiredAccounts() {
    if (!confirm('This will permanently delete all expired temporary accounts. Continue?')) {
        return;
    }

    showLoading('Cleaning up expired accounts...');

    ajaxWithCSRF({
        url: 'cpanel_wp_temp_account.pl',
        method: 'POST',
        data: addCpuserParam({ action: 'cleanup_expired' }),
        dataType: 'json',
        success: function(response) {
            hideLoading();
            if (response.success) {
                const data = response.data;
                let message = `Cleanup complete. Removed ${data.cleaned} expired account(s).`;

                if (data.errors && data.errors.length > 0) {
                    const errors = data.errors.map(err => escapeHtml(err)).join('<br>');
                    message += '<br><br>Errors:<br>' + errors;
                    showWarning(message);
                } else {
                    showSuccess(message);
                }

                loadActiveAccounts();
            } else {
                showError('Cleanup failed: ' + escapeHtml(response.error));
            }
        },
        error: function(xhr, status, error) {
            hideLoading();
            showError('Network error during cleanup: ' + escapeHtml(error));
        }
    });
}

function deleteAccount(domain, username) {
    if (!confirm(`Delete account "${username}" from ${domain}?`)) {
        return;
    }

    showLoading('Deleting account...');

    ajaxWithCSRF({
        url: 'cpanel_wp_temp_account.pl',
        method: 'POST',
        data: addCpuserParam({
            action: 'delete_account',
            domain: domain,
            username: username
        }),
        dataType: 'json',
        success: function(response) {
            hideLoading();
            if (response.success) {
                showSuccess('Account deleted successfully');
                loadActiveAccounts();
            } else {
                showError('Failed to delete account: ' + escapeHtml(response.error));
            }
        },
        error: function(xhr, status, error) {
            hideLoading();
            showError('Network error while deleting account: ' + escapeHtml(error));
        }
    });
}

function showAccountDetails(domain, username, password, url) {
    const loginUrl = sanitizeUrl(url.replace(/\/$/, '') + '/wp-admin');

    const content = `
        <div class="modal-account-details">
            <div class="detail-row">
                <strong>Domain:</strong> ${escapeHtml(domain)}
            </div>
            <div class="detail-row">
                <strong>Username:</strong>
                <span class="credential">${escapeHtml(username)}</span>
                <button class="copy-btn" data-copy="${username}">Copy</button>
            </div>
            ${password ? `
            <div class="detail-row">
                <strong>Password:</strong>
                <span class="credential">${escapeHtml(password)}</span>
                <button class="copy-btn" data-copy="${password}">Copy</button>
            </div>
            ` : '<div class="detail-row"><em>Password not available for viewing</em></div>'}
            <div class="detail-row">
                <strong>Login URL:</strong>
                <a href="${loginUrl}" target="_blank" rel="noopener noreferrer" class="cpanel-link">${escapeHtml(loginUrl)}</a>
                <button class="copy-btn" data-copy="${loginUrl}">Copy</button>
            </div>
            <div class="detail-row">
                <strong>Quick Login:</strong>
                <button class="cpanel-button cpanel-button-primary" id="openWpAdmin">
                    Open WordPress Admin
                </button>
            </div>
        </div>
    `;

    $('#modalContent').html(content);

    // Attach event handlers
    $('#modalContent .copy-btn').on('click', function() {
        copyToClipboard($(this).data('copy'));
    });

    $('#openWpAdmin').on('click', function() {
        window.open(loginUrl, '_blank', 'noopener,noreferrer');
    });

    $('#accountModal').show();
}

function closeModal() {
    $('#accountModal').hide();
}

function copyToClipboard(text) {
    if (!text) return;

    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(function() {
            showSuccess('Copied to clipboard!');
        }, function() {
            fallbackCopyTextToClipboard(text);
        });
    } else {
        fallbackCopyTextToClipboard(text);
    }
}

function fallbackCopyTextToClipboard(text) {
    const textArea = document.createElement('textarea');
    textArea.value = text;
    textArea.style.position = 'fixed';
    textArea.style.left = '-999999px';
    textArea.style.top = '-999999px';
    document.body.appendChild(textArea);
    textArea.focus();
    textArea.select();

    try {
        const successful = document.execCommand('copy');
        if (successful) {
            showSuccess('Copied to clipboard!');
        } else {
            showError('Could not copy to clipboard');
        }
    } catch (err) {
        showError('Could not copy to clipboard');
    }

    document.body.removeChild(textArea);
}

// Message functions with XSS protection
function showLoading(message) {
    $('#statusMessages').html(`
        <div class="cpanel-notice cpanel-notice-info">
            <span class="loading-spinner">⏳</span>
            ${escapeHtml(message)}
        </div>
    `);
}

function hideLoading() {
    $('#statusMessages').empty();
}

function showSuccess(message) {
    // Allow HTML in message but escape if it looks like user input
    const isHtml = message.includes('<');
    const safeMessage = isHtml ? message : escapeHtml(message);

    $('#statusMessages').html(`
        <div class="cpanel-notice cpanel-notice-success">
            <span class="icon">✅</span>
            ${safeMessage}
        </div>
    `);
    setTimeout(hideLoading, 5000);
}

function showError(message) {
    $('#statusMessages').html(`
        <div class="cpanel-notice cpanel-notice-error">
            <span class="icon">❌</span>
            ${escapeHtml(message)}
        </div>
    `);
}

function showWarning(message) {
    // Allow HTML for formatted warnings
    $('#statusMessages').html(`
        <div class="cpanel-notice cpanel-notice-warning">
            <span class="icon">⚠️</span>
            ${message}
        </div>
    `);
}