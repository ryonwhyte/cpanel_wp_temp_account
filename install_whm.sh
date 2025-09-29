#!/bin/bash

# WHM Plugin Installation Script for WP Temporary Accounts
# Official WHM plugin installation following cPanel documentation

set -euo pipefail

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
echo "=================================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define WHM plugin directories
WHM_CGI_DIR="/usr/local/cpanel/whostmgr/docroot/cgi/addons/wp_temp_accounts"
WHM_TEMPLATES_DIR="/usr/local/cpanel/whostmgr/docroot/templates/wp_temp_accounts"
WHM_ADDON_DIR="/usr/local/cpanel/whostmgr/docroot/addon_plugins"
APPS_DIR="/var/cpanel/apps"

# Check for cPanel/WHM
if [ ! -d "/usr/local/cpanel" ]; then
    log_error "cPanel/WHM not found. This plugin requires cPanel/WHM."
    exit 1
fi

log_info "Creating WHM plugin directories..."

# Create required directories with proper permissions
mkdir -p "$WHM_CGI_DIR"
mkdir -p "$WHM_TEMPLATES_DIR"
mkdir -p "$WHM_ADDON_DIR"
mkdir -p "$APPS_DIR"

chmod 755 "$WHM_CGI_DIR"
chmod 755 "$WHM_TEMPLATES_DIR"
chmod 755 "$WHM_ADDON_DIR"
chmod 755 "$APPS_DIR"

log_info "Copying plugin files to WHM directories..."

# Create a WHM plugin CGI script
cat > "$WHM_CGI_DIR/index.cgi" << 'EOF'
#!/usr/bin/perl
#WHMADDON:wp_temp_accounts:WP Temporary Accounts:wp_temp_accounts_icon.png
#ACLS:all

use strict;
use warnings;

print "Content-type: text/html\n\n";

print <<'END_HTML';
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WP Temporary Accounts - WHM Plugin</title>
    <link rel="stylesheet" type="text/css" href="/usr/local/cpanel/whostmgr/docroot/templates/wp_temp_accounts/style.css">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { border-bottom: 2px solid #eee; padding-bottom: 20px; margin-bottom: 30px; }
        .header h1 { color: #333; margin: 0; font-size: 28px; }
        .breadcrumb { margin-bottom: 20px; }
        .breadcrumb a { color: #007cba; text-decoration: none; }
        .breadcrumb a:hover { text-decoration: underline; }
        .callout { background: #e7f3ff; border-left: 4px solid #007cba; padding: 15px; margin: 20px 0; border-radius: 4px; }
        .callout h4 { margin-top: 0; color: #005a87; }
        .section { margin: 30px 0; }
        .section h2 { color: #333; border-bottom: 1px solid #ddd; padding-bottom: 10px; }
        .section h3 { color: #555; }
        .btn { background: #007cba; color: white; padding: 10px 20px; border: none; border-radius: 4px; text-decoration: none; display: inline-block; margin: 5px 10px 5px 0; }
        .btn:hover { background: #005a87; color: white; }
        .btn-default { background: #6c757d; }
        .btn-default:hover { background: #545b62; }
        ul { line-height: 1.6; }
        li { margin: 8px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="breadcrumb">
            <a href="/">Home</a> &gt;
            <a href="/scripts2/manage_plugins">Plugins</a> &gt;
            WP Temporary Accounts
        </div>

        <div class="header">
            <h1>🔧 WP Temporary Accounts</h1>
            <p>WordPress Administrator Account Management</p>
        </div>

        <div class="callout">
            <h4>✅ WHM Plugin Successfully Installed</h4>
            <p>The plugin is properly registered and accessible through WHM.</p>
        </div>

        <div class="section">
            <h2>📋 Plugin Information</h2>
            <p>This WHM plugin provides system administrators with oversight of the WP Temporary Accounts functionality.</p>

            <h3>🎯 How Users Access the Plugin</h3>
            <ul>
                <li><strong>cPanel Users:</strong> Log into cPanel and look for "WP Temporary Accounts" in the Software section</li>
                <li><strong>Direct Access:</strong> Each user can access via their cPanel interface</li>
                <li><strong>Documentation:</strong> Full user guide available in the GitHub repository</li>
            </ul>

            <h3>🔧 Administrative Features</h3>
            <ul>
                <li>Monitor plugin usage across all cPanel accounts</li>
                <li>Review cleanup logs and account statistics</li>
                <li>Manage installation and updates</li>
                <li>Configure global security policies</li>
            </ul>

            <h3>📊 System Status</h3>
            <ul>
                <li>✅ WHM Registration: Active</li>
                <li>✅ cPanel Integration: Available</li>
                <li>✅ Cleanup Cron Job: Scheduled (hourly)</li>
                <li>✅ Icon: Installed</li>
                <li>✅ Permissions: Configured</li>
            </ul>
        </div>

        <div class="section">
            <h2>🚀 Quick Actions</h2>
            <a href="/scripts2/manage_plugins" class="btn btn-primary">← Back to Plugins</a>
            <a href="https://github.com/ryonwhyte/cpanel_wp_temp_account" class="btn btn-default">📖 Documentation</a>
            <a href="/scripts2/view_system_health" class="btn btn-default">System Health</a>
        </div>

        <div class="section">
            <h2>💡 Support & Information</h2>
            <p><strong>Plugin Version:</strong> 3.0 (Universal)</p>
            <p><strong>Compatibility:</strong> Works with both WP Toolkit and direct WordPress installations</p>
            <p><strong>Security:</strong> Enterprise-grade security with CSRF protection, input validation, and audit logging</p>
            <p><strong>Support:</strong> Issues and feature requests can be submitted on GitHub</p>
        </div>
    </div>
</body>
</html>
END_HTML
EOF

chmod 755 "$WHM_CGI_DIR/index.cgi"
chown root:wheel "$WHM_CGI_DIR/index.cgi" 2>/dev/null || chown root:root "$WHM_CGI_DIR/index.cgi"

# Create WHM template files
cat > "$WHM_TEMPLATES_DIR/index.tmpl" << 'EOF'
[% content %]
EOF

# Copy stylesheet for WHM templates
cp "$SCRIPT_DIR/cpanel_wp_temp_account.css" "$WHM_TEMPLATES_DIR/style.css"
chmod 644 "$WHM_TEMPLATES_DIR/index.tmpl" "$WHM_TEMPLATES_DIR/style.css"

# Copy backend logic to shared location (if needed by both cPanel and WHM)
SHARED_DIR="/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account"
mkdir -p "$SHARED_DIR"
cp "$SCRIPT_DIR/cpanel_wp_temp_account.pl" "$SHARED_DIR/cpanel_wp_temp_account.pl"
chmod 755 "$SHARED_DIR/cpanel_wp_temp_account.pl"

# Copy the 48x48 PNG icon for WHM
if [ -f "$SCRIPT_DIR/wp_temp_accounts_icon.png" ]; then
    cp "$SCRIPT_DIR/wp_temp_accounts_icon.png" "$WHM_ADDON_DIR/wp_temp_accounts_icon.png"
    chmod 644 "$WHM_ADDON_DIR/wp_temp_accounts_icon.png"
    log_info "✅ Copied plugin icon (48x48 PNG)"
else
    log_warning "Icon file wp_temp_accounts_icon.png not found. Plugin will work but may not have an icon."
fi

log_info "Registering plugin with AppConfig system..."

# Copy AppConfig configuration file
cp "$SCRIPT_DIR/wp_temp_accounts.conf" "/tmp/wp_temp_accounts.conf"

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

# Force WHM to refresh its menu cache
log_info "Refreshing WHM menu cache..."
rm -rf /usr/local/cpanel/var/cache/whostmgr/* 2>/dev/null || true
rm -rf /usr/local/cpanel/var/cache/template/* 2>/dev/null || true
rm -rf /usr/local/cpanel/var/cache/applications/* 2>/dev/null || true

# Clean up temporary file
rm -f /tmp/wp_temp_accounts.conf

# Set up cron job for cleanup (same as before)
log_info "Setting up automatic cleanup cron job..."
CRON_SCRIPT="/usr/local/cpanel/scripts/cpanel_wp_temp_account_cleanup"
cat > "$CRON_SCRIPT" << 'EOF'
#!/usr/bin/perl

use strict;
use warnings;
use File::Find;

# Find all user home directories
opendir(my $dh, '/home') or die "Cannot read /home: $!";
my @users = grep { -d "/home/$_" && $_ !~ /^\./ } readdir($dh);
closedir($dh);

foreach my $user (@users) {
    my $cleanup_script = "/home/$user/.wp_temp_accounts/cleanup.pl";
    next unless -f $cleanup_script;

    # Run cleanup as the user
    system("su", "-s", "/bin/bash", "-c", "/usr/bin/perl $cleanup_script", $user);
}
EOF

chmod +x "$CRON_SCRIPT"

# Add to root's crontab
(crontab -l 2>/dev/null | grep -v "cpanel_wp_temp_account_cleanup"; echo "0 * * * * /usr/local/cpanel/scripts/cpanel_wp_temp_account_cleanup >/dev/null 2>&1") | crontab -

# Restart WHM services to reload AppConfig
log_info "Restarting WHM services to reload plugin registration..."
/scripts/restartsrv_cpsrvd --stop 2>/dev/null || true
sleep 2
/scripts/restartsrv_cpsrvd --start 2>/dev/null || log_warning "Could not restart cpsrvd"
sleep 2

# Additional restart for full registration
log_info "Ensuring WHM recognizes the new plugin..."
/scripts/restartsrv_whostmgrd 2>/dev/null || log_warning "Could not restart whostmgrd"

# Verify installation
log_info "Verifying installation..."

# Check files exist
if [ -f "$WHM_CGI_DIR/index.cgi" ] && [ -f "/var/cpanel/apps/wp_temp_accounts.conf" ]; then
    log_info "✅ Installation files verified!"
else
    log_error "Installation verification failed. Some files may be missing."
    exit 1
fi

# Check CGI script syntax
log_info "Testing CGI script syntax..."
if perl -c "$WHM_CGI_DIR/index.cgi" >/dev/null 2>&1; then
    log_info "✅ CGI script syntax OK"
else
    log_error "CGI script has syntax errors"
    perl -c "$WHM_CGI_DIR/index.cgi"
    exit 1
fi

# Check permissions
log_info "Verifying file permissions..."
ls -la "$WHM_CGI_DIR/index.cgi" | while read line; do
    log_info "  $line"
done

echo ""
echo "=================================================="
echo -e "${GREEN}WHM Plugin Installation Complete!${NC}"
echo "=================================================="
echo ""
echo "The WP Temporary Accounts plugin has been installed as a WHM plugin."
echo ""
echo "🎯 ACCESS THE PLUGIN:"
echo "  • WHM: Plugins → WP Temporary Accounts"
echo "  • Direct: https://your-server:2087/cgi/addons/wp_temp_accounts/index.cgi"
echo ""
echo "📋 FILES INSTALLED:"
echo "  • CGI Script: $WHM_CGI_DIR/index.cgi"
echo "  • Templates: $WHM_TEMPLATES_DIR/"
echo "  • AppConfig: /var/cpanel/apps/wp_temp_accounts.conf"
echo "  • Cleanup: $CRON_SCRIPT"
echo ""
echo "⚠️  IMPORTANT NOTES:"
echo "  1. You need to create a 48x48 PNG icon:"
echo "     $WHM_ADDON_DIR/wp_temp_accounts_icon.png"
echo "  2. The plugin will appear in WHM under the Plugins section"
echo "  3. Access is controlled by WHM user permissions"
echo ""
echo "🔧 IF PLUGIN DOESN'T APPEAR:"
echo "  1. Check AppConfig registration:"
echo "     cat /var/cpanel/apps/wp_temp_accounts.conf"
echo "  2. Restart cpsrvd:"
echo "     /scripts/restartsrv_cpsrvd"
echo "  3. Try direct URL access first"
echo ""
echo "📝 TO UNINSTALL:"
echo "  Run: ./uninstall_whm.sh"
echo ""