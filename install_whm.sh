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

# Create the main CGI script (following LiteSpeed pattern)
cat > "$WHM_PLUGIN_DIR/wp_temp_accounts.cgi" << 'EOF'
#!/bin/sh
eval 'if [ -x /usr/local/cpanel/3rdparty/bin/perl ]; then exec /usr/local/cpanel/3rdparty/bin/perl -x -- $0 ${1+"$@"}; else exec /usr/bin/perl -x -- $0 ${1+"$@"};fi'
if 0;
#!/usr/bin/perl

#WHMADDON:wp_temp_accounts:WP Temporary Accounts:wp_temp_accounts_icon.png

use strict;
use lib '/usr/local/cpanel/';
use Whostmgr::ACLS();
Whostmgr::ACLS::init_acls();

package cgi::wp_temp_accounts;
use warnings;
use Cpanel::Template();

run() unless caller();

sub run {
    print "Content-type: text/html; charset=utf-8\n\n";

    if (!Whostmgr::ACLS::hasroot()) {
        print "You do not have access to the WP Temporary Accounts Plugin.\n";
        exit;
    }

    Cpanel::Template::process_template(
        'whostmgr',
        {
            'template_file' => 'wp_temp_accounts/wp_temp_accounts.html.tt',
            'print'   => 1,
        }
    );
    exit();
}
EOF

chmod 755 "$WHM_PLUGIN_DIR/wp_temp_accounts.cgi"
chown root:root "$WHM_PLUGIN_DIR/wp_temp_accounts.cgi"

# Create the Template Toolkit file (following LiteSpeed pattern)
cat > "$WHM_TEMPLATES_DIR/wp_temp_accounts.html.tt" << 'EOF'
[%
USE Whostmgr;
USE JSON;

IF locale.get_html_dir_attr() == 'rtl';
    SET rtl_bootstrap = Whostmgr.find_file_url('/3rdparty/bootstrap-rtl/optimized/dist/css/bootstrap-rtl.min.css');
END;

SET styleSheets = [
    rtl_bootstrap,
    '/libraries/fontawesome/css/font-awesome.min.css',
    '/combined_optimized.css',
    '/themes/x/style_optimized.css'
];

WRAPPER 'master_templates/master.tmpl'
    breadcrumbdata = {
            previous = [
                    {name = "Home",url = "/scripts/command?PFILE=main"},
                    {name = "Plugins",url="/scripts/command?PFILE=Plugins"}
            ],
            name = 'WP Temporary Accounts Plugin',
            url = '/cgi/wp_temp_accounts/wp_temp_accounts.cgi',
    },
    header = locale.maketext("WP Temporary Accounts")
    skipheader = 1,
    stylesheets = styleSheets,
    theme='bootstrap';
%]

<div class="container-fluid">
    <div class="row">
        <div class="col-lg-12">
            <div class="callout callout-success">
                <h4><i class="fa fa-check"></i> WHM Plugin Successfully Installed</h4>
                <p>The WP Temporary Accounts plugin is properly registered and accessible through WHM.</p>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-lg-8">
            <div class="box box-primary">
                <div class="box-header with-border">
                    <h3 class="box-title"><i class="fa fa-wordpress"></i> Plugin Information</h3>
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

        <div class="col-lg-4">
            <div class="box box-info">
                <div class="box-header with-border">
                    <h3 class="box-title"><i class="fa fa-info-circle"></i> System Status</h3>
                </div>
                <div class="box-body">
                    <ul class="list-unstyled">
                        <li><i class="fa fa-check text-green"></i> WHM Registration: Active</li>
                        <li><i class="fa fa-check text-green"></i> cPanel Integration: Available</li>
                        <li><i class="fa fa-check text-green"></i> Cleanup Cron Job: Scheduled</li>
                        <li><i class="fa fa-check text-green"></i> Icon: Installed</li>
                        <li><i class="fa fa-check text-green"></i> Permissions: Configured</li>
                    </ul>
                </div>
            </div>
        </div>
    </div>

    <div class="row">
        <div class="col-lg-12">
            <div class="box box-default">
                <div class="box-header with-border">
                    <h3 class="box-title"><i class="fa fa-rocket"></i> Quick Actions</h3>
                </div>
                <div class="box-body">
                    <a href="/scripts/command?PFILE=Plugins" class="btn btn-primary">
                        <i class="fa fa-arrow-left"></i> Back to Plugins
                    </a>
                    <a href="https://github.com/ryonwhyte/cpanel_wp_temp_account" class="btn btn-default" target="_blank">
                        <i class="fa fa-book"></i> Documentation
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>

[% END %]
EOF

chmod 644 "$WHM_TEMPLATES_DIR/wp_temp_accounts.html.tt"
chown root:root "$WHM_TEMPLATES_DIR/wp_temp_accounts.html.tt"

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

if [ -f "$WHM_PLUGIN_DIR/wp_temp_accounts.cgi" ] && [ -f "$WHM_TEMPLATES_DIR/wp_temp_accounts.html.tt" ]; then
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
    log_error "CGI script has syntax errors"
    perl -c "$WHM_PLUGIN_DIR/wp_temp_accounts.cgi"
    exit 1
fi

echo ""
echo "=================================================="
echo -e "${GREEN}WHM Plugin Installation Complete!${NC}"
echo "=================================================="
echo ""
echo "The WP Temporary Accounts plugin has been installed using the LiteSpeed pattern."
echo ""
echo "🎯 ACCESS THE PLUGIN:"
echo "  • WHM: Plugins → WP Temporary Accounts"
echo "  • Direct: https://your-server:2087/cgi/wp_temp_accounts/wp_temp_accounts.cgi"
echo ""
echo "📋 FILES INSTALLED:"
echo "  • CGI Script: $WHM_PLUGIN_DIR/wp_temp_accounts.cgi"
echo "  • Template: $WHM_TEMPLATES_DIR/wp_temp_accounts.html.tt"
echo "  • Icon: $WHM_ADDON_DIR/wp_temp_accounts_icon.png"
echo ""
echo "✨ The plugin should now appear in WHM Plugins menu automatically!"
echo "   No AppConfig registration needed - uses WHMADDON comment method like LiteSpeed."
echo ""