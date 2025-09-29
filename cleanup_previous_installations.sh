#!/bin/bash

# Complete Cleanup Script for Previous WP Temporary Accounts Installations
# This removes ALL traces of previous plugin versions and registration attempts

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

echo "============================================================"
echo "Complete Cleanup: Previous WP Temporary Accounts Installations"
echo "============================================================"
echo ""
echo "This will remove ALL traces of previous plugin installations."
echo "This includes files, registrations, features, and configurations."
echo ""
read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
log_info "Starting comprehensive cleanup..."

# 1. Remove cPanel plugin directories and files
echo ""
log_info "1. Removing cPanel plugin directories..."

CPANEL_DIRS=(
    "/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account"
    "/usr/local/cpanel/base/frontend/jupiter/cpanel_wp_temp_account"
    "/usr/local/cpanel/base/frontend/x3/cpanel_wp_temp_account"
)

for dir in "${CPANEL_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        log_info "   ✅ Removed: $dir"
    fi
done

# 2. Remove WHM plugin directories and files
echo ""
log_info "2. Removing WHM plugin directories..."

WHM_DIRS=(
    "/usr/local/cpanel/whostmgr/docroot/cgi/wp_temp_accounts"
    "/usr/local/cpanel/whostmgr/docroot/templates/wp_temp_accounts"
    "/usr/local/cpanel/whostmgr/docroot/cgi/cpanel_wp_temp_account"
    "/usr/local/cpanel/whostmgr/docroot/templates/cpanel_wp_temp_account"
)

for dir in "${WHM_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        log_info "   ✅ Removed: $dir"
    fi
done

# 3. Remove plugin registration files
echo ""
log_info "3. Removing plugin registration files..."

REGISTRATION_FILES=(
    "/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account.cpanelplugin"
    "/usr/local/cpanel/base/frontend/jupiter/cpanel_wp_temp_account.cpanelplugin"
    "/usr/local/cpanel/base/frontend/x3/cpanel_wp_temp_account.cpanelplugin"
    "/var/cpanel/apps/cpanel_wp_temp_account.conf"
    "/var/cpanel/apps/wp_temp_accounts.conf"
    "/var/cpanel/apps/cpanel_wp_temp_account.yaml"
    "/var/cpanel/apps/wp_temp_accounts.yaml"
)

for file in "${REGISTRATION_FILES[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        log_info "   ✅ Removed: $file"
    fi
done

# 4. Remove icons and assets
echo ""
log_info "4. Removing icons and assets..."

ICON_FILES=(
    "/usr/local/cpanel/whostmgr/docroot/addon_plugins/wp_temp_accounts_icon.png"
    "/usr/local/cpanel/whostmgr/docroot/addon_plugins/cpanel_wp_temp_account_icon.png"
    "/usr/local/cpanel/whostmgr/docroot/addon_plugins/cpanel_wp_temp_account.png"
    "/usr/local/cpanel/base/frontend/paper_lantern/styled/sprites/cpanel_wp_temp_account.css"
    "/usr/local/cpanel/base/frontend/paper_lantern/sprites/cpanel_wp_temp_account.conf"
)

for file in "${ICON_FILES[@]}"; do
    if [ -f "$file" ]; then
        rm -f "$file"
        log_info "   ✅ Removed: $file"
    fi
done

# 5. Remove DynamicUI configurations
echo ""
log_info "5. Removing DynamicUI configurations..."

DYNAMICUI_FILES=(
    "/usr/local/cpanel/base/frontend/paper_lantern/dynamicui/dynamicui_cpanel_wp_temp_account.conf"
    "/usr/local/cpanel/base/frontend/paper_lantern/dynamicui/cpanel_wp_temp_account.yaml"
    "/usr/local/cpanel/base/frontend/paper_lantern/dynamicui/dynamicui_item_cpanel_wp_temp_account.yaml"
    "/usr/local/cpanel/base/frontend/paper_lantern/config/group_software.yaml"
)

for file in "${DYNAMICUI_FILES[@]}"; do
    if [ -f "$file" ]; then
        # For group_software.yaml, remove only our entries
        if [[ "$file" == *"group_software.yaml" ]]; then
            if grep -q "cpanel_wp_temp_account" "$file" 2>/dev/null; then
                sed -i '/cpanel_wp_temp_account/,+5d' "$file" 2>/dev/null || true
                log_info "   ✅ Removed entries from: $file"
            fi
        else
            rm -f "$file"
            log_info "   ✅ Removed: $file"
        fi
    fi
done

# 6. Remove cPanel features
echo ""
log_info "6. Removing cPanel features..."

FEATURE_NAMES=(
    "wp_temp_accounts"
    "cpanel_wp_temp_account"
    "feature-cpanel_wp_temp_account"
)

for feature in "${FEATURE_NAMES[@]}"; do
    if /usr/local/cpanel/bin/manage_features list 2>/dev/null | grep -q "$feature"; then
        /usr/local/cpanel/bin/manage_features remove --feature "$feature" 2>/dev/null || true
        log_info "   ✅ Removed feature: $feature"
    fi
done

# 7. Clean user feature flags
echo ""
log_info "7. Cleaning user feature flags..."

USER_FILES=/var/cpanel/users/*
for userfile in $USER_FILES; do
    if [ -f "$userfile" ]; then
        username=$(basename "$userfile")
        if [ "$username" != "root" ] && [ "$username" != "nobody" ]; then
            if grep -q "cpanel_wp_temp_account\|wp_temp_accounts" "$userfile" 2>/dev/null; then
                sed -i '/cpanel_wp_temp_account/d' "$userfile" 2>/dev/null || true
                sed -i '/wp_temp_accounts/d' "$userfile" 2>/dev/null || true
                log_info "   ✅ Cleaned features for user: $username"
            fi
        fi
    fi
done

# 8. Remove ACL entries
echo ""
log_info "8. Removing ACL entries..."

ACL_FILES=(
    "/usr/local/cpanel/etc/acls/reseller"
    "/usr/local/cpanel/etc/acls/user"
)

for aclfile in "${ACL_FILES[@]}"; do
    if [ -f "$aclfile" ]; then
        if grep -q "cpanel_wp_temp_account\|wp_temp_accounts" "$aclfile" 2>/dev/null; then
            sed -i '/cpanel_wp_temp_account/d' "$aclfile" 2>/dev/null || true
            sed -i '/wp_temp_accounts/d' "$aclfile" 2>/dev/null || true
            log_info "   ✅ Cleaned ACL file: $aclfile"
        fi
    fi
done

# 9. Remove cron jobs and scripts
echo ""
log_info "9. Removing cron jobs and cleanup scripts..."

CRON_SCRIPTS=(
    "/usr/local/cpanel/scripts/cpanel_wp_temp_account_cleanup"
    "/usr/local/cpanel/scripts/wp_temp_accounts_cleanup"
)

for script in "${CRON_SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        rm -f "$script"
        log_info "   ✅ Removed script: $script"
    fi
done

# Remove cron entries
crontab -l 2>/dev/null | grep -v "cpanel_wp_temp_account\|wp_temp_accounts" | crontab - 2>/dev/null || true
log_info "   ✅ Removed cron job entries"

# 10. Remove application configurations
echo ""
log_info "10. Removing application configurations..."

APP_CONFIGS=(
    "/usr/local/cpanel/etc/applications/cpanel_wp_temp_account.conf"
    "/usr/local/cpanel/etc/applications/cpanel_wp_temp_account.yaml"
    "/usr/local/cpanel/etc/applications/wp_temp_accounts.conf"
    "/usr/local/cpanel/etc/applications/wp_temp_accounts.yaml"
)

for config in "${APP_CONFIGS[@]}"; do
    if [ -f "$config" ]; then
        rm -f "$config"
        log_info "   ✅ Removed: $config"
    fi
done

# 11. Remove template files
echo ""
log_info "11. Removing template files..."

TEMPLATE_FILES=(
    "/usr/local/cpanel/whostmgr/docroot/templates/cpanel_wp_temp_account.tt"
    "/usr/local/cpanel/base/frontend/paper_lantern/styled/retro/applications/cpanel_wp_temp_account.html.tt"
)

for template in "${TEMPLATE_FILES[@]}"; do
    if [ -f "$template" ]; then
        rm -f "$template"
        log_info "   ✅ Removed: $template"
    fi
done

# 12. Clear all caches
echo ""
log_info "12. Clearing all cPanel caches..."

CACHE_DIRS=(
    "/usr/local/cpanel/var/cache/*"
    "/home/*/.cpanel/cache/*"
    "/home/*/.cpanel/nvdata/*"
    "/var/cpanel/userdata/*/cache"
)

for cache_pattern in "${CACHE_DIRS[@]}"; do
    rm -rf $cache_pattern 2>/dev/null || true
done

rm -f /usr/local/cpanel/.cpanel/nvdata/*.cache 2>/dev/null || true
log_info "   ✅ All caches cleared"

# 13. Optional: Remove user data
echo ""
read -p "Remove all user plugin data (~/.wp_temp_accounts/)? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "13. Removing user data directories..."
    for user_home in /home/*; do
        if [ -d "$user_home/.wp_temp_accounts" ]; then
            rm -rf "$user_home/.wp_temp_accounts"
            log_info "   ✅ Removed data for: $(basename $user_home)"
        fi
    done
else
    log_info "13. Skipping user data removal"
fi

# 14. Rebuild everything
echo ""
log_info "14. Rebuilding cPanel components..."

/usr/local/cpanel/bin/rebuild_sprites 2>/dev/null || true
/usr/local/cpanel/scripts/update_featurelists 2>/dev/null || true
/usr/local/cpanel/scripts/rebuildhttpdconf 2>/dev/null || true
/usr/local/cpanel/scripts/build_cpnat 2>/dev/null || true

log_info "   ✅ Components rebuilt"

# 15. Restart services
echo ""
log_info "15. Restarting cPanel services..."

/scripts/restartsrv_cpsrvd --hard 2>/dev/null || /scripts/restartsrv_cpsrvd
/scripts/restartsrv_httpd 2>/dev/null || true

log_info "   ✅ Services restarted"

echo ""
echo "============================================================"
echo -e "${GREEN}✅ COMPLETE CLEANUP FINISHED!${NC}"
echo "============================================================"
echo ""
echo "All traces of previous WP Temporary Accounts installations have been removed:"
echo ""
echo "Removed:"
echo "  • All cPanel plugin files and directories"
echo "  • All WHM plugin files and directories"
echo "  • All registration files (.cpanelplugin, AppConfig, etc.)"
echo "  • All icons and assets"
echo "  • All DynamicUI configurations"
echo "  • All cPanel features and ACL entries"
echo "  • All user feature flags"
echo "  • All cron jobs and cleanup scripts"
echo "  • All application configurations"
echo "  • All template files"
echo "  • All caches"
if [[ $REPLY =~ ^[Yy]$ ]]; then
echo "  • All user data directories"
fi
echo ""
echo "Your system is now clean and ready for a fresh WHM plugin installation."
echo ""
echo "To install the new WHM plugin:"
echo "  ./install_whm.sh"
echo ""