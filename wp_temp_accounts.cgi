#!/usr/bin/perl

# WHM Plugin CGI Wrapper for WP Temporary Accounts
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
require '/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account/cpanel_wp_temp_account.pl';

# Run the main plugin
main();