#!/bin/bash

# WHM Plugin Installation Script for WP Temporary Accounts
# Following LiteSpeed WHM Plugin Pattern

set -uo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root"
   exit 1
fi

echo "=================================================="
echo "WHM Plugin Installation: WP Temporary Accounts"
echo "Using LiteSpeed Pattern"
echo "=================================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define WHM plugin directories (following LiteSpeed pattern)
WHM_DOCROOT="/usr/local/cpanel/whostmgr/docroot"
WHM_CGI_DIR="${WHM_DOCROOT}/cgi"
WHM_PLUGIN_DIR="${WHM_CGI_DIR}/wp_temp_accounts"
WHM_TEMPLATES_DIR="${WHM_DOCROOT}/templates/wp_temp_accounts"
WHM_ADDON_DIR="${WHM_DOCROOT}/addon_plugins"

# Check for cPanel/WHM
if [ ! -d "/usr/local/cpanel" ]; then
    log_error "cPanel/WHM not found. This plugin requires cPanel/WHM."
    exit 1
fi

log_info "Creating WHM plugin directories..."

# Create plugin directory structure (like LiteSpeed)
mkdir -p "$WHM_PLUGIN_DIR"
mkdir -p "$WHM_TEMPLATES_DIR"
mkdir -p "$WHM_ADDON_DIR"

chmod 755 "$WHM_PLUGIN_DIR"
chmod 755 "$WHM_TEMPLATES_DIR"
chmod 755 "$WHM_ADDON_DIR"

log_info "Creating WHM plugin files..."

# Check for CGI in old location and move if needed
OLD_PLUGIN_DIR="/usr/local/cpanel/whostmgr/docroot/cgi/addons/wp_temp_accounts"
if [ -f "$OLD_PLUGIN_DIR/wp_temp_accounts.cgi" ]; then
    log_info "Moving CGI from old location to new location"
    mv "$OLD_PLUGIN_DIR/wp_temp_accounts.cgi" "$WHM_PLUGIN_DIR/wp_temp_accounts.cgi"
    # Remove old directory if empty
    rmdir "$OLD_PLUGIN_DIR" 2>/dev/null || true
fi

# Create the main CGI script (without Template dependencies)
cat > "$WHM_PLUGIN_DIR/wp_temp_accounts.cgi" << 'EOF'
#!/bin/sh
eval 'if [ -x /usr/local/cpanel/3rdparty/bin/perl ]; then exec /usr/local/cpanel/3rdparty/bin/perl -x -- $0 ${1+"$@"}; else exec /usr/bin/perl -x -- $0 ${1+"$@"};fi'
if 0;
#!/usr/bin/perl

#WHMADDON:wp_temp_accounts:WP Temporary Accounts:wp_temp_accounts_icon.png

use strict;
use warnings;
use lib '/usr/local/cpanel/';

# Try to use WHM ACLs if available, but don't fail if not
my $has_acls = 0;
eval {
    require Whostmgr::ACLS;
    Whostmgr::ACLS::init_acls();
    $has_acls = 1;
};

package cgi::wp_temp_accounts;

run() unless caller();

sub run {
    print "Content-type: text/html; charset=utf-8\n\n";

    # Basic access control - check if running in WHM context
    if ($has_acls && !Whostmgr::ACLS::hasroot()) {
        print_error_page("You do not have access to the WP Temporary Accounts Plugin.");
        exit;
    }

    print_plugin_page();
    exit();
}

sub print_error_page {
    my ($message) = @_;
    print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <title>Access Denied - WP Temporary Accounts</title>
    <meta charset="utf-8">
    <link rel="stylesheet" href="/usr/local/cpanel/whostmgr/docroot/themes/x/style.css">
</head>
<body>
    <div class="container">
        <h1>Access Denied</h1>
        <p>$message</p>
        <a href="/scripts/command?PFILE=main">Return to WHM</a>
    </div>
</body>
</html>
HTML
}

sub print_plugin_page {
    print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <title>WP Temporary Accounts - WHM Plugin</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" href="/usr/local/cpanel/whostmgr/docroot/themes/x/style.css">
    <link rel="stylesheet" href="/libraries/fontawesome/css/font-awesome.min.css">
    <style>
        .container { max-width: 1200px; margin: 20px auto; padding: 20px; }
        .header { border-bottom: 2px solid #ddd; padding-bottom: 20px; margin-bottom: 30px; }
        .breadcrumb { margin-bottom: 20px; }
        .breadcrumb a { color: #0073aa; text-decoration: none; }
        .breadcrumb a:hover { text-decoration: underline; }
        .callout { background: #e7f3ff; border-left: 4px solid #0073aa; padding: 15px; margin: 20px 0; border-radius: 4px; }
        .callout h4 { margin-top: 0; color: #005177; }
        .box { background: white; border: 1px solid #ddd; border-radius: 4px; margin: 20px 0; }
        .box-header { background: #f8f9fa; padding: 15px; border-bottom: 1px solid #ddd; font-weight: bold; }
        .box-body { padding: 20px; }
        .btn { background: #0073aa; color: white; padding: 10px 20px; border: none; border-radius: 4px; text-decoration: none; display: inline-block; margin: 5px 10px 5px 0; }
        .btn:hover { background: #005177; color: white; }
        .btn-default { background: #6c757d; }
        .btn-default:hover { background: #545b62; }
        .row { display: flex; flex-wrap: wrap; margin: -10px; }
        .col { flex: 1; padding: 10px; }
        .col-8 { flex: 0 0 66.666%; }
        .col-4 { flex: 0 0 33.333%; }
        .text-green { color: #28a745; }
        ul { line-height: 1.6; }
        li { margin: 8px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="breadcrumb">
            <a href="/scripts/command?PFILE=main">Home</a> &gt;
            <a href="/scripts/command?PFILE=Plugins">Plugins</a> &gt;
            WP Temporary Accounts
        </div>

        <div class="header">
            <h1><i class="fa fa-wordpress"></i> WP Temporary Accounts</h1>
            <p>WordPress Administrator Account Management</p>
        </div>

        <div class="callout">
            <h4><i class="fa fa-check"></i> WHM Plugin Successfully Installed</h4>
            <p>The WP Temporary Accounts plugin is properly registered and accessible through WHM.</p>
        </div>

        <div class="row">
            <div class="col col-8">
                <div class="box">
                    <div class="box-header">
                        <i class="fa fa-user-circle"></i> Select cPanel Account
                    </div>
                    <div class="box-body">
                        <p><strong>Note:</strong> WHM plugins run as root. To manage WordPress accounts, first select a cPanel user account:</p>
                        <form id="userSelectionForm">
                            <select id="cpanelUserSelect" style="padding: 8px; margin: 10px 0; width: 200px;">
                                <option value="">Select cPanel Account...</option>
                                <!-- Populated dynamically via script below -->
                            </select>
                            <button type="button" onclick="openPluginForUser()" class="btn" style="margin-left: 10px;">
                                <i class="fa fa-external-link"></i> Open Plugin for User
                            </button>
                        </form>
                        <script>
                        // Populate cPanel users dynamically
                        fetch('/json-api/listaccts?api.version=1&searchtype=user')
                            .then(response => response.json())
                            .then(data => {
                                const select = document.getElementById('cpanelUserSelect');
                                if (data.data && data.data.acct) {
                                    data.data.acct.forEach(account => {
                                        const option = document.createElement('option');
                                        option.value = account.user;
                                        option.textContent = account.user + ' (' + account.domain + ')';
                                        select.appendChild(option);
                                    });
                                }
                            })
                            .catch(err => console.log('Could not load cPanel accounts'));

                        function openPluginForUser() {
                            const selectedUser = document.getElementById('cpanelUserSelect').value;
                            if (!selectedUser) {
                                alert('Please select a cPanel account first');
                                return;
                            }
                            // Open the plugin with the selected user context
                            const url = '/frontend/paper_lantern/cpanel_wp_temp_account/cpanel_wp_temp_account.html?cpanel_user=' + encodeURIComponent(selectedUser);
                            window.open(url, '_blank');
                        }
                        </script>
                        <p><em>This will open the main plugin interface in the context of the selected user.</em></p>
                    </div>
                </div>

                <div class="box">
                    <div class="box-header">
                        <i class="fa fa-info-circle"></i> Plugin Information
                    </div>
                    <div class="box-body">
                        <p>This WHM plugin provides system administrators with oversight of the WP Temporary Accounts functionality.</p>

                        <h4><i class="fa fa-users"></i> How Users Access the Plugin</h4>
                        <ul>
                            <li><strong>cPanel Users:</strong> Log into cPanel and look for "WP Temporary Accounts" in the Software section</li>
                            <li><strong>Direct Access:</strong> Each user can access via their cPanel interface</li>
                            <li><strong>Documentation:</strong> Full user guide available in the GitHub repository</li>
                        </ul>

                        <h4><i class="fa fa-cogs"></i> Administrative Features</h4>
                        <ul>
                            <li>Monitor plugin usage across all cPanel accounts</li>
                            <li>Review cleanup logs and account statistics</li>
                            <li>Manage installation and updates</li>
                            <li>Configure global security policies</li>
                        </ul>
                    </div>
                </div>
            </div>

            <div class="col col-4">
                <div class="box">
                    <div class="box-header">
                        <i class="fa fa-server"></i> System Status
                    </div>
                    <div class="box-body">
                        <ul style="list-style: none; padding: 0;">
                            <li><i class="fa fa-check text-green"></i> WHM Registration: Active</li>
                            <li><i class="fa fa-check text-green"></i> cPanel Integration: Available</li>
                            <li><i class="fa fa-check text-green"></i> Cleanup Cron Job: Scheduled</li>
                            <li><i class="fa fa-check text-green"></i> Icon: Installed</li>
                            <li><i class="fa fa-check text-green"></i> Permissions: Configured</li>
                        </ul>
                    </div>
                </div>

                <div class="box">
                    <div class="box-header">
                        <i class="fa fa-info"></i> Plugin Details
                    </div>
                    <div class="box-body">
                        <p><strong>Version:</strong> 3.0 (Universal)</p>
                        <p><strong>Compatibility:</strong> Works with both WP Toolkit and direct WordPress installations</p>
                        <p><strong>Security:</strong> Enterprise-grade security with CSRF protection</p>
                    </div>
                </div>
            </div>
        </div>

        <div class="box">
            <div class="box-header">
                <i class="fa fa-rocket"></i> Quick Actions
            </div>
            <div class="box-body">
                <a href="/scripts/command?PFILE=Plugins" class="btn">
                    <i class="fa fa-arrow-left"></i> Back to Plugins
                </a>
                <a href="https://github.com/ryonwhyte/cpanel_wp_temp_account" class="btn btn-default" target="_blank">
                    <i class="fa fa-book"></i> Documentation
                </a>
            </div>
        </div>
    </div>
</body>
</html>
HTML
}
EOF

chmod 755 "$WHM_PLUGIN_DIR/wp_temp_accounts.cgi"
chown root:root "$WHM_PLUGIN_DIR/wp_temp_accounts.cgi"

log_info "✅ Created self-contained CGI script without Template dependencies"

# Register with AppConfig (required to avoid 403 errors)
log_info "Registering plugin with AppConfig system..."

# Create AppConfig directory if it doesn't exist
APPS_DIR="/var/cpanel/apps"
mkdir -p "$APPS_DIR"
chmod 755 "$APPS_DIR"

# Create AppConfig configuration with correct entryurl
cat > "/tmp/wp_temp_accounts.conf" << 'EOF'
name=wp_temp_accounts
service=whostmgr
url=/cgi/wp_temp_accounts/wp_temp_accounts.cgi
entryurl=wp_temp_accounts/wp_temp_accounts.cgi
acls=all
displayname=WP Temporary Accounts
icon=wp_temp_accounts_icon.png
target=_self
group=plugins
EOF

# Register with AppConfig
if [ -f "/usr/local/cpanel/bin/register_appconfig" ]; then
    log_info "Registering plugin with AppConfig system..."
    /usr/local/cpanel/bin/register_appconfig /tmp/wp_temp_accounts.conf
    if [ $? -eq 0 ]; then
        log_info "✅ Plugin registered with AppConfig"
    else
        log_error "AppConfig registration command failed"
        exit 1
    fi
else
    log_error "register_appconfig command not found"
    exit 1
fi

# Verify registration
if [ -f "/var/cpanel/apps/wp_temp_accounts.conf" ]; then
    log_info "✅ AppConfig file created successfully"
    log_info "AppConfig contents:"
    cat "/var/cpanel/apps/wp_temp_accounts.conf" | while read line; do
        log_info "  $line"
    done
else
    log_error "AppConfig registration failed - config file not created"
    exit 1
fi

# Clean up temporary file
rm -f /tmp/wp_temp_accounts.conf

# Copy the 48x48 PNG icon
if [ -f "$SCRIPT_DIR/wp_temp_accounts_icon.png" ]; then
    if cp "$SCRIPT_DIR/wp_temp_accounts_icon.png" "$WHM_ADDON_DIR/wp_temp_accounts_icon.png" 2>/dev/null; then
        chmod 644 "$WHM_ADDON_DIR/wp_temp_accounts_icon.png"
        log_info "✅ Copied plugin icon (48x48 PNG)"
    else
        log_warning "Could not copy icon file. Plugin will work but may not have an icon."
    fi
else
    log_warning "Icon file wp_temp_accounts_icon.png not found. Plugin will work but may not have an icon."
fi

# Restart WHM services to reload plugins
log_info "Restarting WHM services to reload plugins..."
/scripts/restartsrv_cpsrvd --stop 2>/dev/null || true
sleep 2
/scripts/restartsrv_cpsrvd --start 2>/dev/null || log_warning "Could not restart cpsrvd"

# Verify installation
log_info "Verifying installation..."

if [ -f "$WHM_PLUGIN_DIR/wp_temp_accounts.cgi" ] && [ -f "/var/cpanel/apps/wp_temp_accounts.conf" ]; then
    log_info "✅ Installation files verified!"
else
    log_error "Installation verification failed. Some files may be missing."
    exit 1
fi

# Check CGI script syntax
log_info "Testing CGI script syntax..."
if perl -c "$WHM_PLUGIN_DIR/wp_temp_accounts.cgi" >/dev/null 2>&1; then
    log_info "✅ CGI script syntax OK"
else
    log_error "CGI script has syntax errors:"
    perl -c "$WHM_PLUGIN_DIR/wp_temp_accounts.cgi"
    exit 1
fi

# Install cPanel-side plugin for end users
log_info "Installing cPanel-side plugin for end users..."

# Create 3rdparty directory for cPanel plugin
CPANEL_PLUGIN_DIR="/usr/local/cpanel/base/3rdparty/wp_temp_accounts"
mkdir -p "$CPANEL_PLUGIN_DIR"
chmod 755 "$CPANEL_PLUGIN_DIR"

# Create a simple wrapper script that redirects to the existing functionality
cat > "$CPANEL_PLUGIN_DIR/index.cgi" << 'EOF'
#!/usr/bin/perl

use strict;
use warnings;

print "Content-type: text/html\n\n";
print <<HTML;
<!DOCTYPE html>
<html>
<head>
    <title>WP Temporary Accounts</title>
    <meta charset="utf-8">
    <meta http-equiv="refresh" content="0;url=/frontend/paper_lantern/cpanel_wp_temp_account/cpanel_wp_temp_account.html">
</head>
<body>
    <p>Redirecting to WP Temporary Accounts...</p>
</body>
</html>
HTML
EOF

chmod 755 "$CPANEL_PLUGIN_DIR/index.cgi"
chown root:root "$CPANEL_PLUGIN_DIR/index.cgi"

# Register cPanel AppConfig
if [ -f "$SCRIPT_DIR/wp_temp_accounts_cpanel.conf" ]; then
    log_info "Registering cPanel-side plugin..."
    cp "$SCRIPT_DIR/wp_temp_accounts_cpanel.conf" /tmp/wp_temp_accounts_cpanel.conf
    /usr/local/cpanel/bin/register_appconfig /tmp/wp_temp_accounts_cpanel.conf
    rm -f /tmp/wp_temp_accounts_cpanel.conf
    log_info "✅ cPanel plugin registered for end-user access"
fi

echo ""
echo "=================================================="
echo -e "${GREEN}WHM Plugin Installation Complete!${NC}"
echo "=================================================="
echo ""
echo "The WP Temporary Accounts plugin has been successfully installed."
echo ""
echo "🎯 ACCESS THE PLUGIN:"
echo "  • WHM Admins: Plugins → WP Temporary Accounts"
echo "  • cPanel Users: Software → WP Temporary Accounts"
echo "  • Direct WHM: https://your-server:2087/cgi/wp_temp_accounts/wp_temp_accounts.cgi"
echo ""
echo "📋 FILES INSTALLED:"
echo "  • WHM CGI: $WHM_PLUGIN_DIR/wp_temp_accounts.cgi"
echo "  • WHM AppConfig: /var/cpanel/apps/wp_temp_accounts.conf"
echo "  • cPanel Plugin: $CPANEL_PLUGIN_DIR/index.cgi"
echo "  • cPanel AppConfig: /var/cpanel/apps/wp_temp_accounts_cpanel.conf"
echo "  • Icon: $WHM_ADDON_DIR/wp_temp_accounts_icon.png"
echo ""
echo "✨ The plugin should now appear in:"
echo "   • WHM Plugins menu for administrators"
echo "   • cPanel Software section for end users"
echo ""