#!/bin/bash

# Complete cleanup script for WP Temporary Accounts WHM Plugin
# Removes ALL traces of plugin installations (both old and new patterns)

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

echo "=========================================================="
echo "COMPLETE CLEANUP: WP Temporary Accounts WHM Plugin"
echo "Removes ALL traces of both old and new plugin installations"
echo "=========================================================="
echo ""

WHM_DOCROOT="/usr/local/cpanel/whostmgr/docroot"

log_info "🧹 Starting comprehensive cleanup..."

# All possible plugin locations
LOCATIONS_TO_CHECK=(
    "${WHM_DOCROOT}/cgi/wp_temp_accounts"                    # New LiteSpeed pattern
    "${WHM_DOCROOT}/cgi/addons/wp_temp_accounts"             # Old AppConfig pattern
    "${WHM_DOCROOT}/cgi/wp_temp_accounts.cgi"                # Standalone CGI
    "${WHM_DOCROOT}/templates/wp_temp_accounts"              # Template directory
    "${WHM_DOCROOT}/addon_plugins/wp_temp_accounts_icon.png" # Icon file
    "/var/cpanel/apps/wp_temp_accounts.conf"                 # AppConfig registration
    "/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account" # Shared directory
    "/usr/local/cpanel/scripts/cpanel_wp_temp_account_cleanup" # Cleanup script
)

removed_count=0

for location in "${LOCATIONS_TO_CHECK[@]}"; do
    if [ -e "$location" ]; then
        rm -rf "$location"
        log_info "✅ Removed: $location"
        ((removed_count++))
    else
        log_info "ℹ️  Not found: $location"
    fi
done

# Remove from crontab
log_info "🗓️  Removing cron job..."
if crontab -l 2>/dev/null | grep -q "cpanel_wp_temp_account_cleanup"; then
    crontab -l 2>/dev/null | grep -v "cpanel_wp_temp_account_cleanup" | crontab - 2>/dev/null || true
    log_info "✅ Removed cron job"
else
    log_info "ℹ️  No cron job found"
fi

# Clean up user data (ask for confirmation)
echo ""
log_warning "Found user data directories to clean:"
user_data_found=0
for user_home in /home/*; do
    if [ -d "$user_home/.wp_temp_accounts" ]; then
        echo "  📁 $user_home/.wp_temp_accounts"
        ((user_data_found++))
    fi
done

if [ $user_data_found -gt 0 ]; then
    echo ""
    read -p "Remove ALL user data and logs? This cannot be undone! (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for user_home in /home/*; do
            if [ -d "$user_home/.wp_temp_accounts" ]; then
                rm -rf "$user_home/.wp_temp_accounts"
                log_info "🗑️  Removed data for: $(basename $user_home)"
                ((removed_count++))
            fi
        done
    else
        log_info "ℹ️  User data preserved"
    fi
else
    log_info "ℹ️  No user data directories found"
fi

# Comprehensive WHM cache clearing
log_info "🧽 Clearing ALL WHM caches..."
cache_dirs=(
    "/usr/local/cpanel/var/cache/whostmgr"
    "/usr/local/cpanel/var/cache/template"
    "/usr/local/cpanel/var/cache/locale"
    "/usr/local/cpanel/var/cache/applications"
    "/usr/local/cpanel/var/cache"
    "/var/cpanel/sessions"
    "/tmp/wd_cache_*"
)

for cache_dir in "${cache_dirs[@]}"; do
    if [[ "$cache_dir" == *"*"* ]]; then
        # Handle wildcards
        rm -rf $cache_dir 2>/dev/null || true
    else
        rm -rf "$cache_dir"/* 2>/dev/null || true
    fi
done

log_info "✅ Cleared all WHM caches"

# Force restart WHM services with complete cache clear
log_info "🔄 Restarting WHM services with complete cache clear..."
/scripts/restartsrv_cpsrvd --stop 2>/dev/null || true
sleep 3
rm -rf /usr/local/cpanel/var/cache/* 2>/dev/null || true
/scripts/restartsrv_cpsrvd --start 2>/dev/null || log_warning "Could not restart cpsrvd"

# Optional: restart whostmgrd for good measure
/scripts/restartsrv_whostmgrd 2>/dev/null || log_warning "Could not restart whostmgrd"

echo ""
echo "=========================================================="
echo -e "${GREEN}🎉 COMPLETE CLEANUP FINISHED!${NC}"
echo "=========================================================="
echo ""
echo "📊 CLEANUP SUMMARY:"
echo "  • Files/directories removed: $removed_count"
echo "  • WHM caches cleared: ✅"
echo "  • Services restarted: ✅"
echo "  • Cron job removed: ✅"
echo ""
echo "🔥 IMPORTANT: Complete the cleanup in your browser:"
echo "   1. Close ALL WHM browser tabs"
echo "   2. Clear browser cache (Ctrl+Shift+Delete)"
echo "   3. Wait 60 seconds"
echo "   4. Open fresh browser window and log into WHM"
echo ""
echo "✨ The system is now completely clean and ready for a fresh installation!"
echo ""