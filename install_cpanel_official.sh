#!/bin/bash

# WHM/cPanel WP Temporary Account Plugin - Official cPanel Registration
# Uses the official cPanel plugin registration method

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

echo "==========================================="
echo "WHM/cPanel WP Temporary Account Plugin"
echo "Official cPanel Registration Method"
echo "Version: 3.0"
echo "==========================================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define installation directory
INSTALL_DIR="/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account"

# Check for cPanel
if [ ! -d "/usr/local/cpanel" ]; then
    log_error "cPanel not found. This plugin requires cPanel/WHM."
    exit 1
fi

# Check if source files exist
if [ ! -f "$SCRIPT_DIR/cpanel_wp_temp_account.pl" ]; then
    log_error "Source files not found in $SCRIPT_DIR"
    log_error "Please ensure all plugin files are in the same directory as this installer"
    exit 1
fi

# Backup existing installation if it exists
if [ -d "$INSTALL_DIR" ]; then
    BACKUP_DIR="/root/cpanel_wp_temp_account_backup_$(date +%Y%m%d_%H%M%S)"
    log_warning "Existing installation found. Creating backup..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$INSTALL_DIR" "$BACKUP_DIR/"
    log_info "Backup created at: $BACKUP_DIR"
fi

# Create directory
log_info "Creating plugin directory..."
mkdir -p "$INSTALL_DIR"

log_info "Copying plugin files..."

# Copy core plugin files
cp "$SCRIPT_DIR/cpanel_wp_temp_account.pl" "$INSTALL_DIR/cpanel_wp_temp_account.pl"
cp "$SCRIPT_DIR/cpanel_wp_temp_account.js" "$INSTALL_DIR/cpanel_wp_temp_account.js"
cp "$SCRIPT_DIR/cpanel_wp_temp_account.html" "$INSTALL_DIR/cpanel_wp_temp_account.html"
cp "$SCRIPT_DIR/cpanel_wp_temp_account.css" "$INSTALL_DIR/cpanel_wp_temp_account.css"

# Copy icon files
[ -f "$SCRIPT_DIR/icon.svg" ] && cp "$SCRIPT_DIR/icon.svg" "$INSTALL_DIR/icon.svg"
[ -f "$SCRIPT_DIR/icon.css" ] && cp "$SCRIPT_DIR/icon.css" "$INSTALL_DIR/icon.css"

# Copy the .cpanelplugin file to the Paper Lantern root
log_info "Installing cPanel plugin registration file..."
cp "$SCRIPT_DIR/cpanel_wp_temp_account.cpanelplugin" "/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account.cpanelplugin"

# Copy install.json if needed
[ -f "$SCRIPT_DIR/install.json" ] && cp "$SCRIPT_DIR/install.json" "$INSTALL_DIR/install.json"

# Set permissions
log_info "Setting permissions..."
chmod 755 "$INSTALL_DIR/cpanel_wp_temp_account.pl"
chmod 644 "$INSTALL_DIR/cpanel_wp_temp_account.js"
chmod 644 "$INSTALL_DIR/cpanel_wp_temp_account.html"
chmod 644 "$INSTALL_DIR/cpanel_wp_temp_account.css"
[ -f "$INSTALL_DIR/icon.svg" ] && chmod 644 "$INSTALL_DIR/icon.svg"
[ -f "$INSTALL_DIR/icon.css" ] && chmod 644 "$INSTALL_DIR/icon.css"
chown -R cpanel:cpanel "$INSTALL_DIR"
chmod 644 "/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account.cpanelplugin"

# Create the feature for the plugin
log_info "Creating cPanel feature..."
/usr/local/cpanel/bin/manage_features add --feature "wp_temp_accounts" \
    --desc "WP Temporary Accounts - Create and manage temporary WordPress administrator accounts" 2>/dev/null || {
    log_warning "Feature might already exist, continuing..."
}

# Enable the feature for all users
log_info "Enabling feature for all users..."
for user in $(ls /var/cpanel/users/); do
    if [ "$user" != "root" ] && [ "$user" != "nobody" ]; then
        /usr/local/cpanel/bin/manage_features set --user "$user" --features "wp_temp_accounts" 2>/dev/null || {
            log_warning "Could not enable feature for user: $user"
        }
    fi
done

# Create cron job for automatic cleanup
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

# Rebuild cPanel interface
log_info "Rebuilding cPanel interface..."
/usr/local/cpanel/scripts/install_plugin "$SCRIPT_DIR/cpanel_wp_temp_account.cpanelplugin" 2>/dev/null || {
    log_warning "Could not use install_plugin script, trying alternative method..."
}

# Update feature lists
/usr/local/cpanel/bin/rebuild_sprites 2>/dev/null || true
/usr/local/cpanel/scripts/update_featurelists 2>/dev/null || true

# Restart cPanel services
log_info "Restarting cPanel services..."
/scripts/restartsrv_cpsrvd 2>/dev/null || log_warning "Could not restart cpsrvd"

# Clear cPanel cache
log_info "Clearing cPanel cache..."
rm -rf /usr/local/cpanel/var/cache/* 2>/dev/null || true

# Verify installation
log_info "Verifying installation..."

if [ -f "$INSTALL_DIR/cpanel_wp_temp_account.pl" ] && \
   [ -f "$INSTALL_DIR/cpanel_wp_temp_account.js" ] && \
   [ -f "$INSTALL_DIR/cpanel_wp_temp_account.html" ] && \
   [ -f "$INSTALL_DIR/cpanel_wp_temp_account.css" ] && \
   [ -f "/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account.cpanelplugin" ]; then
    log_info "✅ Installation verified successfully!"
else
    log_error "Installation verification failed. Some files may be missing."
    exit 1
fi

# Check if feature was created
if /usr/local/cpanel/bin/manage_features list 2>/dev/null | grep -q "wp_temp_accounts"; then
    log_info "✅ Feature created successfully!"
else
    log_warning "Feature may not have been created properly"
fi

echo ""
echo "==========================================="
echo -e "${GREEN}Installation Complete!${NC}"
echo "==========================================="
echo ""
echo "The WP Temporary Accounts plugin has been installed using the official cPanel method."
echo ""
echo "🔍 IMPORTANT: Plugin Location"
echo "  The plugin should now appear in:"
echo "  • cPanel → Software → WP Temporary Accounts"
echo ""
echo "📌 Direct Access URLs:"
echo "  • cPanel: https://your-domain:2083/frontend/paper_lantern/cpanel_wp_temp_account/cpanel_wp_temp_account.html"
echo "  • WHM: https://your-server:2087/frontend/paper_lantern/cpanel_wp_temp_account/cpanel_wp_temp_account.html"
echo ""
echo "⚙️ If the plugin doesn't appear:"
echo "  1. Log out and log back into cPanel"
echo "  2. Check that the feature is enabled for your user:"
echo "     /usr/local/cpanel/bin/manage_features list --user YOUR_USERNAME"
echo "  3. Enable the feature manually:"
echo "     /usr/local/cpanel/bin/manage_features set --user YOUR_USERNAME --features wp_temp_accounts"
echo "  4. Try the direct URL first"
echo ""
echo "📋 Files installed:"
echo "  • Plugin: $INSTALL_DIR/"
echo "  • Registration: /usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account.cpanelplugin"
echo "  • Cleanup cron: $CRON_SCRIPT"
echo ""
echo "📝 To uninstall:"
echo "  Run: $INSTALL_DIR/uninstall.sh"
echo ""