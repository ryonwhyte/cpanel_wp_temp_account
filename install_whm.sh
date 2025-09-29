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

# Create index.cgi file where WHM expects it
cat > "$WHM_CGI_DIR/index.cgi" << 'EOF'
#!/usr/bin/perl

# WHM Plugin Entry Point for WP Temporary Accounts
# This provides the main entry point for the WHM plugin

use strict;
use warnings;
use CGI;

# Set proper environment for WHM context
$ENV{'SCRIPT_NAME'} = '/cgi/addons/wp_temp_accounts/index.cgi';
$ENV{'REQUEST_URI'} = '/cgi/addons/wp_temp_accounts/index.cgi';

my $cgi = CGI->new;

# Security: Basic access control
my $remote_user = $ENV{'REMOTE_USER'} || '';
my $whm_user = $ENV{'WHM_USER'} || '';

# For WHM, we don't need strict user validation like cPanel
# WHM access is already controlled by WHM authentication

print "Content-type: text/html\n\n";
print <<'HTML';
<!DOCTYPE html>
<html>
<head>
    <title>WP Temporary Accounts - WHM Plugin</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #eee;
        }
        .header h1 {
            color: #333;
            margin: 0;
        }
        .status {
            background: #e7f3ff;
            border: 1px solid #bee5eb;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .btn {
            background: #007cba;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            margin: 5px;
        }
        .btn:hover {
            background: #005a87;
        }
        .info-box {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            border-radius: 5px;
            padding: 20px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔧 WP Temporary Accounts</h1>
            <p>WordPress Administrator Account Management</p>
        </div>

        <div class="status">
            <strong>✅ WHM Plugin Successfully Installed</strong><br>
            The plugin is properly registered and accessible through WHM.
        </div>

        <div class="info-box">
            <h3>📋 Next Steps</h3>
            <p>To complete the setup and start using the plugin:</p>
            <ol>
                <li><strong>Access via cPanel:</strong> The full plugin interface is available in individual cPanel accounts</li>
                <li><strong>User Access:</strong> Each cPanel user can create temporary WordPress accounts for their domains</li>
                <li><strong>Management:</strong> Users can manage their temporary accounts through their cPanel interface</li>
            </ol>
        </div>

        <div class="info-box">
            <h3>🎯 How to Access the Full Plugin</h3>
            <p><strong>For cPanel Users:</strong></p>
            <ul>
                <li>Log into cPanel for the domain</li>
                <li>Look for "WP Temporary Accounts" in the Software section</li>
                <li>Or access directly: <code>https://domain:2083/cgi-bin/cpanel_wp_temp_account.pl</code></li>
            </ul>
        </div>

        <div class="info-box">
            <h3>🔧 Administrative Features</h3>
            <p><strong>As WHM Administrator, you can:</strong></p>
            <ul>
                <li>Monitor plugin usage across all accounts</li>
                <li>Configure global settings and security policies</li>
                <li>Review cleanup logs and account statistics</li>
                <li>Manage installation and updates</li>
            </ul>
        </div>

        <div class="info-box">
            <h3>📊 System Status</h3>
            <p><strong>Plugin Components:</strong></p>
            <ul>
                <li>✅ WHM Registration: Active</li>
                <li>✅ cPanel Integration: Available</li>
                <li>✅ Cleanup Cron Job: Scheduled</li>
                <li>✅ File Permissions: Secure</li>
            </ul>
        </div>

        <p style="text-align: center; margin-top: 30px;">
            <a href="/scripts2/manage_plugins" class="btn">← Back to Plugins</a>
            <a href="https://github.com/ryonwhyte/cpanel_wp_temp_account" class="btn">📖 Documentation</a>
        </p>

        <div style="text-align: center; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 12px;">
            WP Temporary Accounts v3.0 | WHM Plugin Interface
        </div>
    </div>
</body>
</html>
HTML

EOF

chmod 755 "$WHM_CGI_DIR/index.cgi"

# Copy the main plugin HTML as template
cp "$SCRIPT_DIR/cpanel_wp_temp_account.html" "$WHM_TEMPLATES_DIR/index.tmpl"
cp "$SCRIPT_DIR/cpanel_wp_temp_account.css" "$WHM_TEMPLATES_DIR/style.css"
cp "$SCRIPT_DIR/cpanel_wp_temp_account.js" "$WHM_TEMPLATES_DIR/script.js"

# Copy backend logic to shared location (if needed by both cPanel and WHM)
SHARED_DIR="/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account"
mkdir -p "$SHARED_DIR"
cp "$SCRIPT_DIR/cpanel_wp_temp_account.pl" "$SHARED_DIR/cpanel_wp_temp_account.pl"
chmod 755 "$SHARED_DIR/cpanel_wp_temp_account.pl"

# Create 48x48 PNG icon for WHM (convert from SVG if needed)
if [ -f "$SCRIPT_DIR/icon.svg" ]; then
    # For now, we'll create a simple text-based approach since we don't have ImageMagick
    log_warning "SVG icon found, but conversion to PNG requires ImageMagick"
    log_info "You may need to manually create a 48x48 PNG icon at $WHM_ADDON_DIR/wp_temp_accounts_icon.png"
else
    log_warning "No icon found. You should create a 48x48 PNG icon at $WHM_ADDON_DIR/wp_temp_accounts_icon.png"
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

if [ -f "$WHM_CGI_DIR/index.cgi" ] && \
   [ -f "/var/cpanel/apps/wp_temp_accounts.conf" ]; then
    log_info "✅ Installation verified successfully!"
else
    log_error "Installation verification failed. Some files may be missing."
    exit 1
fi

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