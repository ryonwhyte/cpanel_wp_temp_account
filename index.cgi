#!/usr/local/cpanel/3rdparty/bin/perl

# WHM Plugin Entry Point for WP Temporary Accounts
# Serves the main HTML interface

use strict;
use warnings;

print "Content-Type: text/html\n\n";

# Serve the HTML interface
open my $fh, '<', 'cpanel_wp_temp_account.html' or do {
    print "<h1>Error: Missing cpanel_wp_temp_account.html</h1>";
    print "<p>The plugin interface file could not be found.</p>";
    exit;
};

local $/;
print <$fh>;
close $fh;