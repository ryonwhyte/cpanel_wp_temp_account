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

# Security: Ensure this runs in WHM context
if (!$ENV{'REMOTE_USER'} && !$ENV{'WHM_USER'}) {
    print "Content-type: text/html\n\n";
    print "<h1>Access Denied</h1><p>This plugin must be accessed through WHM.</p>";
    exit;
}

# Include the main plugin logic
my $main_plugin = '/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account/cpanel_wp_temp_account.pl';

if (-f $main_plugin) {
    require $main_plugin;
    main() if defined &main;
} else {
    print "Content-type: text/html\n\n";
    print "<h1>Plugin Error</h1>";
    print "<p>Main plugin file not found at: $main_plugin</p>";
    print "<p>Please check the installation.</p>";
}
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
    /usr/local/cpanel/bin/register_appconfig /tmp/wp_temp_accounts.conf
    log_info "✅ Plugin registered with AppConfig"
else
    log_error "register_appconfig command not found"
    exit 1
fi

# Verify registration
if [ -f "/var/cpanel/apps/wp_temp_accounts.conf" ]; then
    log_info "✅ AppConfig file created successfully"
else
    log_error "AppConfig registration failed"
    exit 1
fi

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

# Restart WHM services
log_info "Restarting WHM services..."
/scripts/restartsrv_cpsrvd 2>/dev/null || log_warning "Could not restart cpsrvd"

# Verify installation
log_info "Verifying installation..."

if [ -f "$WHM_CGI_DIR/wp_temp_accounts.cgi" ] && \
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
echo "  • Direct: https://your-server:2087/cgi/wp_temp_accounts/wp_temp_accounts.cgi"
echo ""
echo "📋 FILES INSTALLED:"
echo "  • CGI Script: $WHM_CGI_DIR/wp_temp_accounts.cgi"
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