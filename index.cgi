#!/usr/local/cpanel/3rdparty/bin/perl
use strict;
use warnings;

# Never load your .pl here; just return static HTML.
print "Content-Type: text/html; charset=utf-8\n\n";

# Serve the HTML file as-is so JS can make AJAX calls to the .pl
my $file = 'cpanel_wp_temp_account.html';
if (open my $fh, '<', $file) {
    local $/;
    print <$fh>;
    close $fh;
} else {
    print "<h1>WP Temporary Accounts</h1><p>Missing $file in the same directory.</p>";
}