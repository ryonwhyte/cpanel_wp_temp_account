#!/bin/bash

# cPanel Feature Registration Script
# This registers the plugin with cPanel's interface

FEATURE_FILE="/var/cpanel/apps/cpanel_wp_temp_account.conf"

echo "Creating cPanel feature registration..."

cat > "$FEATURE_FILE" << 'EOF'
---
name: cpanel_wp_temp_account
version: 3.0
vendor: Ryon Whyte
url: cpanel_wp_temp_account.html
feature: cpanel_wp_temp_account
helpurl: ''
subtype: application
group: software
order: 99
acls:
  - feature-cpanel_wp_temp_account
demourl: ''
EOF

echo "Rebuilding cPanel feature list..."
/usr/local/cpanel/bin/rebuild_sprites

echo "Restarting cPanel services..."
/scripts/restartsrv_cpsrvd

echo "Feature registration complete!"
echo "The plugin should now appear in cPanel under Software > WP Temporary Accounts"