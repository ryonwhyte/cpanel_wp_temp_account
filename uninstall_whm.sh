#!/bin/bash

# WHM Plugin Uninstallation Script for WP Temporary Accounts
# Removes all WHM plugin files and AppConfig registration

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
echo "WHM Plugin Uninstallation: WP Temporary Accounts"
echo "=================================================="
echo ""

# Define WHM plugin directories
WHM_CGI_DIR="/usr/local/cpanel/whostmgr/docroot/cgi/wp_temp_accounts"
WHM_TEMPLATES_DIR="/usr/local/cpanel/whostmgr/docroot/templates/wp_temp_accounts"
WHM_ADDON_DIR="/usr/local/cpanel/whostmgr/docroot/addon_plugins"
SHARED_DIR="/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account"
APPCONFIG_FILE="/var/cpanel/apps/wp_temp_accounts.conf"
CRON_SCRIPT="/usr/local/cpanel/scripts/cpanel_wp_temp_account_cleanup"

log_info "Removing WHM plugin files..."

# Remove WHM plugin directories
if [ -d "$WHM_CGI_DIR" ]; then
    rm -rf "$WHM_CGI_DIR"
    log_info "✅ Removed CGI directory"
fi

if [ -d "$WHM_TEMPLATES_DIR" ]; then
    rm -rf "$WHM_TEMPLATES_DIR"
    log_info "✅ Removed templates directory"
fi

# Remove icon
if [ -f "$WHM_ADDON_DIR/wp_temp_accounts_icon.png" ]; then
    rm -f "$WHM_ADDON_DIR/wp_temp_accounts_icon.png"
    log_info "✅ Removed plugin icon"
fi

# Remove AppConfig registration
if [ -f "$APPCONFIG_FILE" ]; then
    rm -f "$APPCONFIG_FILE"
    log_info "✅ Removed AppConfig registration"
fi

# Remove shared directory (optional - ask user)
echo ""
read -p "Remove shared plugin files in $SHARED_DIR? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "$SHARED_DIR" ]; then
        rm -rf "$SHARED_DIR"
        log_info "✅ Removed shared directory"
    fi
fi

# Remove cron job
if [ -f "$CRON_SCRIPT" ]; then
    rm -f "$CRON_SCRIPT"
    log_info "✅ Removed cleanup script"
fi

# Remove from crontab
crontab -l 2>/dev/null | grep -v "cpanel_wp_temp_account_cleanup" | crontab - 2>/dev/null || true
log_info "✅ Removed cron job"

# Remove user data (optional - ask user)
echo ""
read -p "Remove all user data and logs in ~/.wp_temp_accounts/? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for user_home in /home/*; do
        if [ -d "$user_home/.wp_temp_accounts" ]; then
            rm -rf "$user_home/.wp_temp_accounts"
            log_info "Removed data for: $(basename $user_home)"
        fi
    done
fi

# Restart WHM services
log_info "Restarting WHM services..."
/scripts/restartsrv_cpsrvd 2>/dev/null || log_warning "Could not restart cpsrvd"

echo ""
echo "=================================================="
echo -e "${GREEN}WHM Plugin Uninstallation Complete!${NC}"
echo "=================================================="
echo ""
echo "The WP Temporary Accounts WHM plugin has been removed."
echo ""
echo "Removed items:"
echo "  • WHM CGI files"
echo "  • WHM templates"
echo "  • AppConfig registration"
echo "  • Plugin icon"
echo "  • Cleanup cron job"
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo "  • User data and logs"
fi
echo ""
echo "The plugin should no longer appear in the WHM Plugins section."
echo ""