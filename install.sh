#!/bin/bash

# WHM/cPanel WP Temporary Account Plugin Installer - Universal Version
# Automated installation script for cPanel/WHM

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
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
echo "WHM/cPanel WP Temporary Account Plugin Installer"
echo "Version: 3.0 (Universal)"
echo "==========================================="
echo ""

# Check prerequisites
log_info "Checking prerequisites..."

# Check for cPanel
if [ ! -d "/usr/local/cpanel" ]; then
    log_error "cPanel not found. This plugin requires cPanel/WHM."
    exit 1
fi

# Check for WP Toolkit
if [ ! -d "/usr/local/cpanel/3rdparty/wp-toolkit" ] && [ ! -f "/usr/local/cpanel/scripts/wpt" ]; then
    log_warning "WP Toolkit might not be installed. The plugin requires WP Toolkit to function."
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check Perl modules
log_info "Checking required Perl modules..."

REQUIRED_MODULES=(
    "CGI"
    "JSON::PP"
    "LWP::UserAgent"
    "HTTP::Request"
    "URI::Escape"
    "Digest::SHA"
    "MIME::Base64"
    "Crypt::CBC"
    "Time::Local"
    "Fcntl"
    "File::Path"
    "Cpanel::Logger"
)

MISSING_MODULES=()

for module in "${REQUIRED_MODULES[@]}"; do
    if ! perl -M"$module" -e '' 2>/dev/null; then
        MISSING_MODULES+=("$module")
    fi
done

if [ ${#MISSING_MODULES[@]} -gt 0 ]; then
    log_warning "The following Perl modules are missing:"
    for module in "${MISSING_MODULES[@]}"; do
        echo "  - $module"
    done
    log_info "Attempting to install missing modules..."

    # Install missing modules
    for module in "${MISSING_MODULES[@]}"; do
        if [[ "$module" == "Crypt::CBC" ]]; then
            /usr/local/cpanel/3rdparty/bin/cpanm Crypt::CBC Crypt::Blowfish 2>/dev/null || {
                log_warning "Failed to install $module. You may need to install it manually."
            }
        elif [[ "$module" != "Cpanel::Logger" ]]; then
            /usr/local/cpanel/3rdparty/bin/cpanm "$module" 2>/dev/null || {
                log_warning "Failed to install $module. You may need to install it manually."
            }
        fi
    done
fi

# Define installation directory
INSTALL_DIR="/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account"
BACKUP_DIR="/root/cpanel_wp_temp_account_backup_$(date +%Y%m%d_%H%M%S)"

# Backup existing installation if it exists
if [ -d "$INSTALL_DIR" ]; then
    log_warning "Existing installation found. Creating backup..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$INSTALL_DIR" "$BACKUP_DIR/"
    log_info "Backup created at: $BACKUP_DIR"
fi

# Create directory
log_info "Creating plugin directory..."
mkdir -p "$INSTALL_DIR"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if source files exist
if [ ! -f "$SCRIPT_DIR/cpanel_wp_temp_account.pl" ]; then
    log_error "Source files not found in $SCRIPT_DIR"
    log_error "Please ensure all plugin files are in the same directory as this installer"
    exit 1
fi

log_info "Copying plugin files..."

# Copy files
cp "$SCRIPT_DIR/cpanel_wp_temp_account.pl" "$INSTALL_DIR/cpanel_wp_temp_account.pl"
cp "$SCRIPT_DIR/cpanel_wp_temp_account.js" "$INSTALL_DIR/cpanel_wp_temp_account.js"
cp "$SCRIPT_DIR/cpanel_wp_temp_account.html" "$INSTALL_DIR/cpanel_wp_temp_account.html"
cp "$SCRIPT_DIR/cpanel_wp_temp_account.css" "$INSTALL_DIR/cpanel_wp_temp_account.css"

# File references are already updated in the source files

# Create plugin.json for metadata
cat > "$INSTALL_DIR/plugin.json" << 'EOF'
{
    "name": "WP Temporary Accounts",
    "version": "2.0",
    "description": "Create and manage temporary WordPress administrator accounts with automatic cleanup",
    "author": "Your Name",
    "url": "https://your-website.com",
    "security_features": {
        "csrf_protection": true,
        "input_validation": true,
        "encrypted_storage": true,
        "secure_password_generation": true
    }
}
EOF

# Create uninstall script
cat > "$INSTALL_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

echo "Uninstalling WP Temporary Accounts Plugin..."

# Remove plugin directory
rm -rf /usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account

# Clean up user data (optional)
read -p "Remove all user data and logs? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    for user_home in /home/*; do
        if [ -d "$user_home/.wp_temp_accounts" ]; then
            rm -rf "$user_home/.wp_temp_accounts"
            echo "Removed data for: $(basename $user_home)"
        fi
    done
fi

echo "Uninstallation complete!"
EOF

chmod +x "$INSTALL_DIR/uninstall.sh"

# Set permissions
log_info "Setting permissions..."
chmod 755 "$INSTALL_DIR/cpanel_wp_temp_account.pl"
chmod 644 "$INSTALL_DIR/cpanel_wp_temp_account.js"
chmod 644 "$INSTALL_DIR/cpanel_wp_temp_account.html"
chmod 644 "$INSTALL_DIR/cpanel_wp_temp_account.css"
chmod 644 "$INSTALL_DIR/plugin.json"
chown -R cpanel:cpanel "$INSTALL_DIR"

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

# Restart cPanel services (optional - usually not needed for plugins)
log_info "Updating cPanel configuration..."
/scripts/rebuildhttpdconf 2>/dev/null || true
/scripts/restartsrv_httpd 2>/dev/null || true

# Verify installation
log_info "Verifying installation..."

if [ -f "$INSTALL_DIR/cpanel_wp_temp_account.pl" ] && \
   [ -f "$INSTALL_DIR/cpanel_wp_temp_account.js" ] && \
   [ -f "$INSTALL_DIR/cpanel_wp_temp_account.html" ] && \
   [ -f "$INSTALL_DIR/cpanel_wp_temp_account.css" ]; then
    log_info "Installation verified successfully!"
else
    log_error "Installation verification failed. Some files may be missing."
    exit 1
fi

echo ""
echo "==========================================="
echo -e "${GREEN}Installation Complete!${NC}"
echo "==========================================="
echo ""
echo "The WP Temporary Accounts plugin has been installed."
echo ""
echo "Access the plugin:"
echo "  - cPanel: Software > WP Temporary Accounts"
echo "  - Direct: /frontend/paper_lantern/cpanel_wp_temp_account/cpanel_wp_temp_account.html"
echo ""
echo "Security Features:"
echo "  ✅ CSRF Protection"
echo "  ✅ Input Validation & Sanitization"
echo "  ✅ XSS Protection"
echo "  ✅ Command Injection Prevention"
echo "  ✅ Secure Password Generation"
echo "  ✅ Encrypted Storage Support"
echo ""
echo "Features:"
echo "  - Automatic host/session detection"
echo "  - Works with both cPanel (port 2083) and WHM (port 2087)"
echo "  - Clean, responsive interface"
echo "  - Automatic cleanup via cron"
echo "  - Detailed logging"
echo ""
echo "Logs and Configuration:"
echo "  - User logs: ~/.wp_temp_accounts/accounts.log"
echo "  - Configuration: ~/.wp_temp_accounts/config.json"
echo "  - System logs: /usr/local/cpanel/logs/error_log"
echo ""
echo "To uninstall:"
echo "  Run: $INSTALL_DIR/uninstall.sh"
echo ""
echo "For support or issues:"
echo "  Check the plugin documentation or contact support"
echo ""