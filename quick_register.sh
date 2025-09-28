#!/bin/bash

# Quick registration script for WP Temporary Accounts plugin
# This is the simplest way to make the plugin appear in cPanel

echo "Quick Registration for WP Temporary Accounts Plugin"
echo "===================================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Step 1: Copy the .cpanelplugin file
echo "Step 1: Installing plugin registration file..."
cp cpanel_wp_temp_account.cpanelplugin /usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account.cpanelplugin
chmod 644 /usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account.cpanelplugin

# Step 2: Create the feature
echo "Step 2: Creating cPanel feature..."
/usr/local/cpanel/bin/manage_features add --feature "wp_temp_accounts" --desc "WP Temporary Accounts"

# Step 3: Enable for all users
echo "Step 3: Enabling feature for all users..."
for user in $(ls /var/cpanel/users/); do
    if [ "$user" != "root" ] && [ "$user" != "nobody" ]; then
        echo "  Enabling for user: $user"
        /usr/local/cpanel/bin/manage_features set --user "$user" --features "wp_temp_accounts"
    fi
done

# Step 4: Rebuild interface
echo "Step 4: Rebuilding cPanel interface..."
/usr/local/cpanel/bin/rebuild_sprites
/usr/local/cpanel/scripts/update_featurelists

# Step 5: Restart services
echo "Step 5: Restarting cPanel..."
/scripts/restartsrv_cpsrvd

echo ""
echo "✅ Registration complete!"
echo ""
echo "The plugin should now appear in cPanel → Software → WP Temporary Accounts"
echo ""
echo "If not visible:"
echo "1. Log out and log back into cPanel"
echo "2. Clear browser cache"
echo "3. Check: /usr/local/cpanel/bin/manage_features list --user YOUR_USERNAME"
echo ""