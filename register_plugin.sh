#!/bin/bash

# Comprehensive cPanel Plugin Registration Script
# This script properly registers the WP Temporary Accounts plugin with cPanel

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

log_info "Registering WP Temporary Accounts plugin with cPanel..."

# Define paths
PLUGIN_DIR="/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account"
FEATURE_FILE="/var/cpanel/apps/cpanel_wp_temp_account.conf"
SPRITE_DIR="/usr/local/cpanel/base/frontend/paper_lantern/sprites"
ICON_DIR="/usr/local/cpanel/base/frontend/paper_lantern/styled/sprites"

# Verify plugin files exist
if [ ! -d "$PLUGIN_DIR" ]; then
    log_error "Plugin directory not found: $PLUGIN_DIR"
    log_error "Please run the installation script first: ./install.sh"
    exit 1
fi

# Create cPanel feature configuration
log_info "Creating cPanel feature configuration..."
cat > "$FEATURE_FILE" << 'EOF'
---
name: cpanel_wp_temp_account
version: 3.0
vendor: Ryon Whyte
url: cpanel_wp_temp_account.html
feature: cpanel_wp_temp_account
helpurl: 'https://github.com/ryonwhyte/cpanel-wp-temp-account'
subtype: application
group: software
order: 95
description: 'Create and manage temporary WordPress administrator accounts'
keywords:
  - wordpress
  - temporary
  - accounts
  - admin
  - security
acls:
  - feature-cpanel_wp_temp_account
demourl: ''
EOF

# Create sprite configuration for the icon
log_info "Setting up plugin icon..."
mkdir -p "$SPRITE_DIR"

cat > "$SPRITE_DIR/cpanel_wp_temp_account.conf" << 'EOF'
---
name: cpanel_wp_temp_account
source: cpanel_wp_temp_account_icon
sizes:
  - 16x16
  - 32x32
  - 48x48
description: WP Temporary Accounts Plugin Icon
EOF

# Copy icon CSS to proper location
if [ -f "$PLUGIN_DIR/icon.css" ]; then
    cp "$PLUGIN_DIR/icon.css" "$ICON_DIR/cpanel_wp_temp_account.css" 2>/dev/null || true
fi

# Set proper permissions
chmod 644 "$FEATURE_FILE"
chown root:wheel "$FEATURE_FILE" 2>/dev/null || chown root:root "$FEATURE_FILE"

# Register the feature with cPanel's ACL system
log_info "Registering feature with cPanel ACL system..."
if [ -f "/usr/local/cpanel/etc/acls/reseller" ]; then
    if ! grep -q "feature-cpanel_wp_temp_account" /usr/local/cpanel/etc/acls/reseller 2>/dev/null; then
        echo "feature-cpanel_wp_temp_account=1" >> /usr/local/cpanel/etc/acls/reseller
    fi
fi

if [ -f "/usr/local/cpanel/etc/acls/user" ]; then
    if ! grep -q "feature-cpanel_wp_temp_account" /usr/local/cpanel/etc/acls/user 2>/dev/null; then
        echo "feature-cpanel_wp_temp_account=1" >> /usr/local/cpanel/etc/acls/user
    fi
fi

# Rebuild cPanel caches and restart services
log_info "Rebuilding cPanel feature cache..."
/usr/local/cpanel/bin/rebuild_sprites 2>/dev/null || log_warning "Could not rebuild sprites"

log_info "Updating cPanel configuration..."
/usr/local/cpanel/scripts/upcp --force 2>/dev/null || true

log_info "Restarting cPanel services..."
/scripts/restartsrv_cpsrvd 2>/dev/null || log_warning "Could not restart cpsrvd"

# Clear cPanel cache
log_info "Clearing cPanel cache..."
rm -rf /usr/local/cpanel/var/cache/* 2>/dev/null || true

# Verify registration
log_info "Verifying plugin registration..."
if [ -f "$FEATURE_FILE" ]; then
    log_info "✅ Feature file created successfully"
else
    log_error "❌ Feature file creation failed"
    exit 1
fi

echo ""
echo "==========================================="
echo -e "${GREEN}Plugin Registration Complete!${NC}"
echo "==========================================="
echo ""
echo "The WP Temporary Accounts plugin should now appear in:"
echo "  • cPanel: Software → WP Temporary Accounts"
echo "  • WHM: Plugins → WP Temporary Accounts"
echo ""
echo "Direct access URLs:"
echo "  • cPanel: https://your-domain:2083/frontend/paper_lantern/cpanel_wp_temp_account/cpanel_wp_temp_account.html"
echo "  • WHM: https://your-server:2087/frontend/paper_lantern/cpanel_wp_temp_account/cpanel_wp_temp_account.html"
echo ""
echo "If the plugin doesn't appear immediately:"
echo "  1. Wait 1-2 minutes for cache refresh"
echo "  2. Log out and log back into cPanel/WHM"
echo "  3. Check that all required Perl modules are installed"
echo ""
echo "For troubleshooting:"
echo "  • Check feature file: $FEATURE_FILE"
echo "  • View cPanel error logs: /usr/local/cpanel/logs/error_log"
echo "  • Test direct URL access first"
echo ""