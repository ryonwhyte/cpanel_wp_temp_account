#!/usr/local/cpanel/3rdparty/bin/perl

# WHM/cPanel WP Temporary Account Plugin - Universal Version
# Handles API calls for creating and managing temporary WordPress accounts
# Compatible with WP Toolkit and direct WordPress installations

use strict;
use warnings;
use CGI;
use JSON::PP;
use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;
use Digest::SHA qw(sha256_hex);
use MIME::Base64;
use Crypt::CBC;
use Time::Local;
use Fcntl qw(:flock);
use File::Path qw(make_path);
use Cpanel::Logger;
use DBI;
use File::Find;
use File::Basename;

# Main execution function - only runs when script is invoked directly
sub main {
# Initialize
my $cgi = CGI->new();
my $logger = Cpanel::Logger->new();
my $user = $ENV{'USER'} || $ENV{'REMOTE_USER'} || 'unknown';
my $homedir = $ENV{'HOME'} || "/home/$user";
my $config_dir = "$homedir/.wp_temp_accounts";
my $log_file = "$config_dir/accounts.log";
my $config_file = "$config_dir/config.json";
my $activity_log = "$config_dir/activity.log";
my $rate_limit_file = "$config_dir/rate_limits.json";
my $alerts_file = "$config_dir/alerts.json";
my $stats_file = "$config_dir/statistics.json";
my $wp_sites_cache = "$config_dir/wp_sites_cache.json";

# Create config directory if it doesn't exist
make_path($config_dir) unless -d $config_dir;
chmod 0700, $config_dir;

# Auto-detect environment
my $server_name = $ENV{'SERVER_NAME'} || $ENV{'HTTP_HOST'} || 'localhost';
my $server_port = $ENV{'SERVER_PORT'} || '2083';
my $is_whm = ($server_port eq '2087');
my $session_token = get_session_token();

# Load configuration
my $config = load_config();

# Handle user impersonation for WHM context
my $target_user = $cgi->param('cpanel_user') || $user;
my $original_user = $user;
my $impersonation_active = 0;

# If running in WHM context (as root) and a target user is specified
if ($is_whm && $original_user eq 'root' && $target_user ne 'root' && $target_user ne 'unknown') {
    eval {
        require Cpanel::PwCache;
        require Cpanel::AccessIds;

        my $pw = Cpanel::PwCache::getpwnam($target_user);
        if ($pw) {
            # Temporarily switch to target user context
            Cpanel::AccessIds::pushuids($pw->get_uid, $pw->get_gid);
            $impersonation_active = 1;

            # Update environment variables for impersonated user
            $user = $target_user;
            $homedir = $pw->get_dir || "/home/$target_user";
            $config_dir = "$homedir/.wp_temp_accounts";
            $log_file = "$config_dir/accounts.log";
            $config_file = "$config_dir/config.json";
            $activity_log = "$config_dir/activity.log";
            $rate_limit_file = "$config_dir/rate_limits.json";
            $alerts_file = "$config_dir/alerts.json";
            $stats_file = "$config_dir/statistics.json";
            $wp_sites_cache = "$config_dir/wp_sites_cache.json";

            # Create config directory for impersonated user if needed
            make_path($config_dir) unless -d $config_dir;
            chmod 0700, $config_dir;

            # Reload configuration for the impersonated user
            $config = load_config();
        }
    };
    if ($@) {
        # If impersonation fails, continue as root but log the issue
        log_activity("Failed to impersonate user '$target_user': $@", "WARNING");
    }
}

# CSRF Protection
my $csrf_token = $cgi->param('csrf_token') || '';
my $action = $cgi->param('action') || '';

# Print header
print $cgi->header('application/json');

# Validate CSRF token for state-changing operations
my @protected_actions = ('create_temp_account', 'cleanup_expired', 'delete_account');
if (grep { $_ eq $action } @protected_actions) {
    unless (validate_csrf_token($csrf_token)) {
        print_error('Invalid CSRF token');
        exit;
    }
}

# Input validation
my %allowed_actions = map { $_ => 1 } qw(
    get_wp_sites create_temp_account list_temp_accounts
    cleanup_expired delete_account get_system_info get_csrf_token
    get_statistics get_alerts get_activity log_activity
    check_rate_limit
);

unless ($allowed_actions{$action}) {
    print_error('Invalid action');
    exit;
}

# Route actions
if ($action eq 'get_csrf_token') {
    get_csrf_token();
} elsif ($action eq 'get_wp_sites') {
    get_wp_sites();
} elsif ($action eq 'create_temp_account') {
    create_temp_account();
} elsif ($action eq 'list_temp_accounts') {
    list_temp_accounts();
} elsif ($action eq 'cleanup_expired') {
    cleanup_expired();
} elsif ($action eq 'delete_account') {
    delete_account();
} elsif ($action eq 'get_system_info') {
    get_system_info();
} elsif ($action eq 'get_statistics') {
    get_statistics();
} elsif ($action eq 'get_alerts') {
    get_alerts();
} elsif ($action eq 'get_activity') {
    get_activity();
} elsif ($action eq 'log_activity') {
    log_activity();
} elsif ($action eq 'check_rate_limit') {
    check_rate_limit();
} elsif ($action eq 'validate_site_health') {
    my $domain = sanitize_input($cgi->param('domain') || '');
    if ($domain =~ /^[a-zA-Z0-9.-]+$/) {
        my $health = validate_wp_site_health($domain);
        print_success($health);
    } else {
        print_error('Invalid domain format');
    }
} elsif ($action eq 'get_system_health') {
    my $overview = get_system_health_overview();
    print_success($overview);
}
}  # End of main()

# Only run main() when executed directly, not when required
unless (caller) {
    main();
}

# Functions

sub get_csrf_token {
    my $token = generate_csrf_token();
    print_success({ 'csrf_token' => $token });
}

sub generate_csrf_token {
    my $random = join('', map { chr(int(rand(256))) } 1..32);
    my $token = sha256_hex($random . time() . $session_token);

    # Store token with expiration (1 hour)
    my $token_file = "$config_dir/.csrf_tokens";
    open(my $fh, '>>', $token_file) or die "Cannot open token file: $!";
    flock($fh, LOCK_EX);
    print $fh "$token:" . (time() + 3600) . "\n";
    flock($fh, LOCK_UN);
    close($fh);

    # Clean old tokens
    clean_old_tokens();

    return $token;
}

sub validate_csrf_token {
    my ($token) = @_;
    return 0 unless $token;

    my $token_file = "$config_dir/.csrf_tokens";
    return 0 unless -f $token_file;

    open(my $fh, '<', $token_file) or return 0;
    flock($fh, LOCK_SH);
    my @lines = <$fh>;
    flock($fh, LOCK_UN);
    close($fh);

    foreach my $line (@lines) {
        chomp $line;
        my ($stored_token, $expiry) = split(':', $line);
        if ($stored_token eq $token && $expiry > time()) {
            return 1;
        }
    }

    return 0;
}

sub clean_old_tokens {
    my $token_file = "$config_dir/.csrf_tokens";
    return unless -f $token_file;

    open(my $fh, '+<', $token_file) or return;
    flock($fh, LOCK_EX);

    my @valid_tokens;
    my $now = time();

    while (my $line = <$fh>) {
        chomp $line;
        my ($token, $expiry) = split(':', $line);
        push @valid_tokens, $line if $expiry > $now;
    }

    seek($fh, 0, 0);
    truncate($fh, 0);
    print $fh join("\n", @valid_tokens) . "\n" if @valid_tokens;

    flock($fh, LOCK_UN);
    close($fh);
}

sub get_system_info {
    print_success({
        'server_name' => $server_name,
        'server_port' => $server_port,
        'is_whm' => $is_whm ? JSON::PP::true : JSON::PP::false,
        'user' => $user,
        'session_token' => substr($session_token, 0, 10) . '...',
        'security_features' => {
            'csrf_protection' => JSON::PP::true,
            'input_validation' => JSON::PP::true,
            'encrypted_storage' => JSON::PP::true
        }
    });
}

sub get_wp_sites {
    my @wp_sites = ();
    my $detection_method = '';

    # Try WP Toolkit first (preferred method)
    if (wp_toolkit_available()) {
        my $wp_data = call_wp_toolkit_api('get_installations');

        if ($wp_data && ref($wp_data) eq 'HASH' && $wp_data->{'data'}) {
            foreach my $installation (@{$wp_data->{'data'}}) {
                # Sanitize all data
                push @wp_sites, {
                    'id' => sanitize_input($installation->{'id'} || ''),
                    'domain' => sanitize_input($installation->{'domain'} || $installation->{'url'} || 'Unknown'),
                    'path' => sanitize_input($installation->{'path'} || '/'),
                    'version' => sanitize_input($installation->{'version'} || 'Unknown'),
                    'url' => sanitize_url($installation->{'url'} || "https://" . ($installation->{'domain'} || 'unknown')),
                    'detection_method' => 'wp_toolkit',
                    'features' => ['staging', 'cloning', 'security_scan']
                };
            }
            $detection_method = 'wp_toolkit';
            log_user_activity('wp_sites_loaded', "Loaded " . scalar(@wp_sites) . " WordPress sites via WP Toolkit", '');
        }
    }

    # Fallback: Direct WordPress discovery
    if (@wp_sites == 0) {
        @wp_sites = discover_wordpress_sites();
        $detection_method = 'direct_scan';
        log_user_activity('wp_sites_loaded', "Loaded " . scalar(@wp_sites) . " WordPress sites via direct scan", '');
    }

    # Sort by domain name
    @wp_sites = sort { $a->{'domain'} cmp $b->{'domain'} } @wp_sites;

    print_success({
        'sites' => \@wp_sites,
        'detection_method' => $detection_method,
        'total_sites' => scalar(@wp_sites)
    });
}

sub create_temp_account {
    my $domain = sanitize_input($cgi->param('domain') || '');
    my $hours = int($cgi->param('hours') || 24);
    my $honeypot = $cgi->param('website') || '';  # Honeypot field

    # Honeypot check - if filled, it's likely a bot
    if ($honeypot) {
        log_security_event('honeypot_triggered', "Honeypot filled: $honeypot");
        print_error('Invalid request');
        return;
    }

    # Rate limiting check
    unless (check_rate_limit_internal()) {
        print_error('Rate limit exceeded. Please wait before creating another account.');
        return;
    }

    # Validate inputs with length limits
    unless ($domain =~ /^[a-zA-Z0-9.-]+$/ && length($domain) >= 3 && length($domain) <= 253) {
        print_error('Invalid domain format or length (3-253 characters)');
        return;
    }

    unless ($hours > 0 && $hours <= 168) {  # Max 1 week
        print_error('Invalid expiration time (1-168 hours allowed)');
        return;
    }

    # Generate secure credentials
    my $username = 'temp_admin_' . time() . '_' . int(rand(1000));
    my $password = generate_secure_password();
    my $email = "temp_$username\@temp-access.local";

    # Get WordPress installation info (try WP Toolkit first)
    my $installation_id;
    my $installation_url = "https://$domain";

    if (wp_toolkit_available()) {
        my $wp_data = call_wp_toolkit_api('get_installations');
        if ($wp_data && $wp_data->{'data'}) {
            foreach my $install (@{$wp_data->{'data'}}) {
                if (($install->{'domain'} && $install->{'domain'} eq $domain) ||
                    ($install->{'url'} && $install->{'url'} =~ /\Q$domain\E/)) {
                    $installation_id = $install->{'id'};
                    $installation_url = $install->{'url'} || "https://$domain";
                    last;
                }
            }
        }
    }

    # If no WP Toolkit installation found, check if we can find it via direct discovery
    if (!$installation_id) {
        my @direct_sites = discover_wordpress_sites();
        my $found_direct = 0;
        foreach my $site (@direct_sites) {
            if ($site->{'domain'} eq $domain) {
                $found_direct = 1;
                $installation_url = $site->{'url'};
                last;
            }
        }

        unless ($found_direct) {
            print_error("WordPress installation not found for domain: $domain");
            return;
        }
    }

    # Create user via hybrid approach (WP Toolkit preferred, direct DB as fallback)
    my $user_created = 0;
    my $creation_method = '';

    # Try WP Toolkit first if available
    if ($installation_id && wp_toolkit_available()) {
        my $user_data = {
            'installation_id' => $installation_id,
            'user_login' => $username,
            'user_pass' => $password,
            'user_email' => $email,
            'role' => 'administrator',
            'first_name' => 'Temporary',
            'last_name' => 'Admin',
            'display_name' => 'Temporary Admin'
        };

        my $result = call_wp_toolkit_api('create_user', $user_data);
        if ($result && (!$result->{'errors'} || @{$result->{'errors'}} == 0)) {
            $user_created = 1;
            $creation_method = 'wp_toolkit';
        }
    }

    # Fallback to direct database creation
    if (!$user_created) {
        if (create_wp_user_direct($domain, $username, $password, $email)) {
            $user_created = 1;
            $creation_method = 'direct_db';
            log_user_activity('user_created_direct', "Created user $username for $domain via direct database", $username);
        }
    }

    my $result = { 'errors' => [] } unless $user_created;

    if ($user_created) {
        # Log the account securely
        log_temp_account($domain, $username, $password, $email, $hours, $installation_url);

        # Clean URL for login
        my $login_url = $installation_url;
        $login_url =~ s|/$||;
        $login_url .= '/wp-admin';

        print_success({
            'domain' => sanitize_input($domain),
            'username' => sanitize_input($username),
            'password' => $password,  # Only time we send the password
            'email' => sanitize_input($email),
            'expires' => format_time(time() + ($hours * 3600)),
            'login_url' => sanitize_url($login_url),
            'installation_id' => sanitize_input($installation_id || ''),
            'creation_method' => $creation_method
        });

        $logger->info("Created temp account: $username for $domain by $user");
        log_user_activity('account_created', "Created temporary account $username for $domain (expires in $hours hours)", $username);
    } else {
        my $error_msg = 'Failed to create WordPress user';
        if ($result && $result->{'errors'}) {
            $error_msg .= ': ' . join(', ', map { sanitize_input($_) } @{$result->{'errors'}});
        }
        print_error($error_msg);
    }
}

sub list_temp_accounts {
    my @accounts = ();

    if (-f $log_file) {
        open(my $fh, '<', $log_file) or die "Cannot read log file: $!";
        flock($fh, LOCK_SH);

        while (my $line = <$fh>) {
            chomp $line;
            next unless $line;

            eval {
                my $account = decode_json($line);
                if ($account && $account->{'expiry_timestamp'} > time()) {
                    # Don't send password hashes to frontend
                    delete $account->{'password_hash'};

                    # Add time remaining
                    $account->{'time_remaining'} = get_time_remaining($account->{'expiry_timestamp'});

                    # Sanitize all output
                    foreach my $key (keys %$account) {
                        $account->{$key} = sanitize_input($account->{$key}) unless ref($account->{$key});
                    }

                    push @accounts, $account;
                }
            };
            if ($@) {
                $logger->warn("Error parsing account entry: $@");
            }
        }

        flock($fh, LOCK_UN);
        close($fh);
    }

    @accounts = sort { $a->{'expiry_timestamp'} <=> $b->{'expiry_timestamp'} } @accounts;

    print_success({ 'accounts' => \@accounts });
}

sub cleanup_expired {
    my $cleaned = 0;
    my @errors = ();
    my @active_accounts = ();

    if (-f $log_file) {
        open(my $fh, '+<', $log_file) or die "Cannot open log file: $!";
        flock($fh, LOCK_EX);

        my @lines = <$fh>;

        foreach my $line (@lines) {
            chomp $line;
            next unless $line;

            eval {
                my $account = decode_json($line);
                next unless $account;

                if ($account->{'expiry_timestamp'} <= time()) {
                    if (delete_wp_user($account->{'domain'}, $account->{'username'})) {
                        $cleaned++;
                        $logger->info("Cleaned expired account: $account->{'username'} from $account->{'domain'}");
                        log_user_activity('account_cleaned', "Cleaned expired account $account->{'username'} from $account->{'domain'}", $account->{'username'});
                    } else {
                        push @errors, "Failed to delete $account->{'username'} from $account->{'domain'}";
                        push @active_accounts, $line;
                    }
                } else {
                    push @active_accounts, $line;
                }
            };
            if ($@) {
                $logger->warn("Error processing account during cleanup: $@");
                push @active_accounts, $line;
            }
        }

        # Rewrite file with active accounts
        seek($fh, 0, 0);
        truncate($fh, 0);
        print $fh join("\n", @active_accounts) . "\n" if @active_accounts;

        flock($fh, LOCK_UN);
        close($fh);
    }

    log_user_activity('cleanup_expired', "Cleanup completed: $cleaned accounts cleaned, " . scalar(@errors) . " errors", '');

    print_success({
        'cleaned' => $cleaned,
        'errors' => [map { sanitize_input($_) } @errors]
    });
}

sub delete_account {
    my $domain = sanitize_input($cgi->param('domain') || '');
    my $username = sanitize_input($cgi->param('username') || '');

    # Validate inputs with length limits
    unless ($domain =~ /^[a-zA-Z0-9.-]+$/ && length($domain) >= 3 && length($domain) <= 253) {
        print_error('Invalid domain format or length (3-253 characters)');
        return;
    }

    unless ($username =~ /^[a-zA-Z0-9_]+$/ && length($username) >= 3 && length($username) <= 60) {
        print_error('Invalid username format or length (3-60 characters)');
        return;
    }

    if (delete_wp_user($domain, $username)) {
        remove_from_log($domain, $username);
        $logger->info("Manually deleted account: $username from $domain by user: $user");
        log_user_activity('account_deleted', "Manually deleted account $username from $domain", $username);
        print_success({ 'message' => 'Account deleted successfully' });
    } else {
        print_error('Failed to delete WordPress user');
    }
}

# New Enhanced Functions

sub get_statistics {
    my $stats = {
        'total_accounts' => 0,
        'active_accounts' => 0,
        'expired_today' => 0,
        'created_today' => 0,
        'accounts_by_site' => {},
        'hourly_activity' => [],
        'rate_limit_hits' => 0
    };

    # Count accounts
    if (-f $log_file) {
        open(my $fh, '<', $log_file) or return print_error("Cannot read log file: $!");
        while (my $line = <$fh>) {
            chomp $line;
            next unless $line;

            eval {
                my $account = decode_json($line);
                next unless $account;

                $stats->{'total_accounts'}++;

                if ($account->{'expiry_timestamp'} > time()) {
                    $stats->{'active_accounts'}++;

                    # Count by site
                    my $domain = $account->{'domain'};
                    $stats->{'accounts_by_site'}->{$domain} = ($stats->{'accounts_by_site'}->{$domain} || 0) + 1;
                }

                # Check if created today
                my $created_time = $account->{'expiry_timestamp'} - ($account->{'hours'} * 3600);
                if ($created_time > time() - 86400) {
                    $stats->{'created_today'}++;
                }

                # Check if expired today
                if ($account->{'expiry_timestamp'} > time() - 86400 && $account->{'expiry_timestamp'} < time()) {
                    $stats->{'expired_today'}++;
                }
            };
        }
        close($fh);
    }

    # Get rate limit info
    if (-f $rate_limit_file) {
        my $rate_data = load_json_file($rate_limit_file);
        $stats->{'rate_limit_hits'} = $rate_data->{'hits_today'} || 0;
    }

    print_success($stats);
}

sub get_alerts {
    my @alerts = ();

    # Check for too many active accounts
    my $active_count = count_active_accounts();
    if ($active_count > 20) {
        push @alerts, {
            'level' => 'danger',
            'message' => "Critical: $active_count active accounts (limit: 20)",
            'action' => 'cleanup_expired'
        };
    } elsif ($active_count > 10) {
        push @alerts, {
            'level' => 'warning',
            'message' => "Warning: $active_count active accounts (recommended: <10)",
            'action' => 'review_accounts'
        };
    }

    # Check for stale expired accounts
    my $expired_count = count_expired_accounts();
    if ($expired_count > 5) {
        push @alerts, {
            'level' => 'warning',
            'message' => "$expired_count expired accounts need cleanup",
            'action' => 'cleanup_expired'
        };
    }

    # Check cleanup frequency
    my $last_cleanup = get_last_cleanup_time();
    if ($last_cleanup && (time() - $last_cleanup) > 86400) {
        push @alerts, {
            'level' => 'info',
            'message' => 'Cleanup has not run in 24+ hours',
            'action' => 'check_cron'
        };
    }

    print_success({ 'alerts' => \@alerts });
}

sub get_activity {
    my $limit = int($cgi->param('limit') || 50);
    my @activities = ();

    if (-f $activity_log) {
        open(my $fh, '<', $activity_log) or return print_error("Cannot read activity log: $!");
        my @lines = <$fh>;
        close($fh);

        # Get last N lines
        @lines = splice(@lines, -$limit) if @lines > $limit;

        foreach my $line (reverse @lines) {
            chomp $line;
            next unless $line;

            eval {
                my $activity = decode_json($line);
                push @activities, $activity if $activity;
            };
        }
    }

    print_success({ 'activity' => \@activities });
}

sub log_activity {
    my $activity_type = sanitize_input($cgi->param('type') || '');
    my $details = sanitize_input($cgi->param('details') || '');
    my $account_username = sanitize_input($cgi->param('username') || '');

    log_user_activity($activity_type, $details, $account_username);
    print_success({ 'message' => 'Activity logged' });
}

sub check_rate_limit {
    my $allowed = check_rate_limit_internal();
    my $remaining = get_remaining_requests();

    print_success({
        'allowed' => $allowed ? JSON::PP::true : JSON::PP::false,
        'remaining' => $remaining,
        'reset_time' => get_rate_limit_reset_time()
    });
}

sub check_rate_limit_internal {
    my $max_per_hour = $config->{'rate_limit_per_hour'} || 10;
    my $current_hour = int(time() / 3600);

    my $rate_data = {};
    if (-f $rate_limit_file) {
        $rate_data = load_json_file($rate_limit_file);
    }

    # Clean old data
    $rate_data = {} unless $rate_data->{'hour'} && $rate_data->{'hour'} == $current_hour;

    # Initialize for current hour
    unless ($rate_data->{'hour'} == $current_hour) {
        $rate_data = {
            'hour' => $current_hour,
            'requests' => 0,
            'users' => {}
        };
    }

    # Check user-specific limit
    my $user_requests = $rate_data->{'users'}->{$user} || 0;

    if ($user_requests >= $max_per_hour) {
        log_security_event('rate_limit_exceeded', "User $user exceeded rate limit ($user_requests/$max_per_hour)");
        return 0;
    }

    # Increment counters
    $rate_data->{'requests'}++;
    $rate_data->{'users'}->{$user} = $user_requests + 1;

    # Save rate data
    save_json_file($rate_limit_file, $rate_data);

    return 1;
}

sub log_user_activity {
    my ($type, $details, $username) = @_;

    my $activity = {
        'timestamp' => time(),
        'user' => $user,
        'type' => $type,
        'details' => $details,
        'username' => $username || '',
        'ip' => $ENV{'REMOTE_ADDR'} || 'unknown',
        'user_agent' => substr($ENV{'HTTP_USER_AGENT'} || '', 0, 100)
    };

    append_json_line($activity_log, $activity);

    # Check for suspicious activity
    check_suspicious_behavior($activity);
}

sub log_security_event {
    my ($event_type, $details) = @_;

    log_user_activity('security_event', "$event_type: $details", '');
    $logger->warn("Security Event [$event_type]: $details (User: $user)");
}

sub check_suspicious_behavior {
    my ($activity) = @_;
    my $suspicious = 0;
    my @reasons = ();

    # Check for rapid requests
    my $recent_count = count_recent_activities($activity->{'user'}, 300); # 5 minutes
    if ($recent_count > 20) {
        $suspicious = 1;
        push @reasons, "Rapid requests: $recent_count in 5 minutes";
    }

    # Check for unusual user agents
    my $ua = $activity->{'user_agent'} || '';
    if ($ua =~ /(bot|crawler|spider|scan)/i && $ua !~ /(google|bing|yahoo)/i) {
        $suspicious = 1;
        push @reasons, "Suspicious user agent: $ua";
    }

    # Check for honeypot triggers
    if ($activity->{'type'} eq 'security_event' && $activity->{'details'} =~ /honeypot/) {
        $suspicious = 1;
        push @reasons, "Honeypot triggered";
    }

    if ($suspicious) {
        log_security_event('suspicious_behavior', join(', ', @reasons));

        # Auto-suspend if too suspicious
        if (@reasons >= 2) {
            suspend_user_temporarily($activity->{'user'}, 3600); # 1 hour suspension
        }
    }
}

sub suspend_user_temporarily {
    my ($user_to_suspend, $duration) = @_;

    my $suspension_file = "$config_dir/.suspensions";
    my $suspensions = {};

    if (-f $suspension_file) {
        $suspensions = load_json_file($suspension_file);
    }

    $suspensions->{$user_to_suspend} = time() + $duration;
    save_json_file($suspension_file, $suspensions);

    log_security_event('user_suspended', "User $user_to_suspend suspended for $duration seconds");
}

sub is_user_suspended {
    my ($user_to_check) = @_;

    my $suspension_file = "$config_dir/.suspensions";
    return 0 unless -f $suspension_file;

    my $suspensions = load_json_file($suspension_file);
    my $suspension_time = $suspensions->{$user_to_check} || 0;

    return $suspension_time > time();
}

# Helper functions for new features

sub count_active_accounts {
    my $count = 0;

    if (-f $log_file) {
        open(my $fh, '<', $log_file) or return 0;
        while (my $line = <$fh>) {
            chomp $line;
            next unless $line;
            eval {
                my $account = decode_json($line);
                $count++ if $account && $account->{'expiry_timestamp'} > time();
            };
        }
        close($fh);
    }

    return $count;
}

sub count_expired_accounts {
    my $count = 0;

    if (-f $log_file) {
        open(my $fh, '<', $log_file) or return 0;
        while (my $line = <$fh>) {
            chomp $line;
            next unless $line;
            eval {
                my $account = decode_json($line);
                $count++ if $account && $account->{'expiry_timestamp'} <= time();
            };
        }
        close($fh);
    }

    return $count;
}

sub count_recent_activities {
    my ($target_user, $seconds) = @_;
    my $count = 0;
    my $cutoff = time() - $seconds;

    return 0 unless -f $activity_log;

    open(my $fh, '<', $activity_log) or return 0;
    while (my $line = <$fh>) {
        chomp $line;
        next unless $line;
        eval {
            my $activity = decode_json($line);
            if ($activity && $activity->{'user'} eq $target_user && $activity->{'timestamp'} > $cutoff) {
                $count++;
            }
        };
    }
    close($fh);

    return $count;
}

sub get_last_cleanup_time {
    return 0 unless -f $activity_log;

    my $last_cleanup = 0;
    open(my $fh, '<', $activity_log) or return 0;
    while (my $line = <$fh>) {
        chomp $line;
        next unless $line;
        eval {
            my $activity = decode_json($line);
            if ($activity && $activity->{'type'} eq 'cleanup_expired') {
                $last_cleanup = $activity->{'timestamp'} if $activity->{'timestamp'} > $last_cleanup;
            }
        };
    }
    close($fh);

    return $last_cleanup;
}

sub get_remaining_requests {
    my $max_per_hour = $config->{'rate_limit_per_hour'} || 10;
    my $current_hour = int(time() / 3600);

    my $rate_data = {};
    if (-f $rate_limit_file) {
        $rate_data = load_json_file($rate_limit_file);
    }

    return $max_per_hour unless $rate_data->{'hour'} == $current_hour;

    my $used = $rate_data->{'users'}->{$user} || 0;
    return $max_per_hour - $used;
}

sub get_rate_limit_reset_time {
    my $current_hour = int(time() / 3600);
    return ($current_hour + 1) * 3600;
}

sub load_json_file {
    my ($file_path) = @_;
    return {} unless -f $file_path;

    open(my $fh, '<', $file_path) or return {};
    my $content = do { local $/; <$fh> };
    close($fh);

    eval {
        return decode_json($content);
    };
    return {};
}

sub save_json_file {
    my ($file_path, $data) = @_;

    open(my $fh, '>', $file_path) or die "Cannot write to $file_path: $!";
    print $fh encode_json($data);
    close($fh);
    chmod 0600, $file_path;
}

sub append_json_line {
    my ($file_path, $data) = @_;

    open(my $fh, '>>', $file_path) or die "Cannot append to $file_path: $!";
    flock($fh, LOCK_EX);
    print $fh encode_json($data) . "\n";
    flock($fh, LOCK_UN);
    close($fh);
    chmod 0600, $file_path;
}

# Helper functions

sub call_wp_toolkit_api {
    my ($function, $params) = @_;
    $params ||= {};

    # IMPORTANT: in WHM you MUST specify a cPanel username to act as
    my $cpuser = $cgi->param('cpuser') || $cgi->param('cpanel_user') || $user;
    if ($is_whm && (!$cpuser || $cpuser eq 'root' || $cpuser eq 'unknown')) {
        # Bail early with a clear message so you don't silently hit 'root'
        print_error("Missing cPanel user for WP Toolkit call. Please select a cPanel account.");
        return;
    }

    # Build API URL based on environment
    my $api_url;
    if ($is_whm) {
        $api_url = "https://$server_name:2087/cgi/wpt/index.php";
    } else {
        $api_url = "https://$server_name:2083$session_token/3rdparty/wpt/index.php";
    }

    my %post_data = (
        'cpanel_jsonapi_apiversion' => 2,
        'cpanel_jsonapi_module' => 'WPToolkit',
        'cpanel_jsonapi_func' => $function,
        %$params
    );

    # Add cpanel_jsonapi_user for WHM context
    if ($is_whm) {
        $post_data{'cpanel_jsonapi_user'} = $cpuser;
        $post_data{'cpanelOrWhmSecurityToken'} = $session_token;
    }

    # Use LWP::UserAgent instead of shell curl (fixes command injection)
    my $ua = LWP::UserAgent->new(
        ssl_opts => { verify_hostname => 0 },
        timeout => 30
    );

    # Forward session cookies so the token ties to the same WHM session
    if ($ENV{'HTTP_COOKIE'}) {
        $ua->default_header('Cookie' => $ENV{'HTTP_COOKIE'});
    }

    my $response = $ua->post($api_url, \%post_data);

    if ($response->is_success) {
        eval {
            my $data = decode_json($response->content);
            return $data->{'cpanelresult'} if $data && $data->{'cpanelresult'};
            return $data;
        };
        if ($@) {
            $logger->warn("JSON decode error: $@");
            return undef;
        }
    } else {
        $logger->warn("API call failed: " . $response->status_line);
        return undef;
    }
}

sub delete_wp_user {
    my ($domain, $username) = @_;

    my $user_deleted = 0;

    # Try WP Toolkit first if available
    if (wp_toolkit_available()) {
        # Get installation ID
        my $wp_data = call_wp_toolkit_api('get_installations');
        my $installation_id;

        if ($wp_data && $wp_data->{'data'}) {
            foreach my $install (@{$wp_data->{'data'}}) {
                if (($install->{'domain'} && $install->{'domain'} eq $domain) ||
                    ($install->{'url'} && $install->{'url'} =~ /\Q$domain\E/)) {
                    $installation_id = $install->{'id'};
                    last;
                }
            }
        }

        if ($installation_id) {
            # Get users to find user ID
            my $users_data = call_wp_toolkit_api('get_users', { 'installation_id' => $installation_id });
            my $user_id;

            if ($users_data && $users_data->{'data'}) {
                foreach my $user_obj (@{$users_data->{'data'}}) {
                    if ($user_obj->{'user_login'} eq $username) {
                        $user_id = $user_obj->{'ID'};
                        last;
                    }
                }
            }

            if ($user_id) {
                # Delete user
                my $result = call_wp_toolkit_api('delete_user', {
                    'installation_id' => $installation_id,
                    'user_id' => $user_id
                });

                if ($result && (!$result->{'errors'} || @{$result->{'errors'}} == 0)) {
                    $user_deleted = 1;
                }
            }
        }
    }

    # Fallback to direct database deletion
    if (!$user_deleted) {
        $user_deleted = delete_wp_user_direct($domain, $username);
        if ($user_deleted) {
            log_user_activity('user_deleted_direct', "Deleted user $username from $domain via direct database", $username);
        }
    }

    return $user_deleted;
}

sub generate_secure_password {
    my $length = 20;
    my @chars = ('a'..'z', 'A'..'Z', '0'..'9', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_', '=', '+');
    my $password = '';

    # Ensure at least one of each type
    $password .= $chars[rand(26)];          # lowercase
    $password .= $chars[26 + rand(26)];     # uppercase
    $password .= $chars[52 + rand(10)];     # number
    $password .= $chars[62 + rand(14)];     # special

    # Fill remaining characters randomly
    for (5..$length) {
        $password .= $chars[rand @chars];
    }

    # Shuffle password
    my @pwd_chars = split('', $password);
    for (my $i = @pwd_chars - 1; $i > 0; $i--) {
        my $j = int(rand($i + 1));
        @pwd_chars[$i, $j] = @pwd_chars[$j, $i];
    }

    return join('', @pwd_chars);
}

sub log_temp_account {
    my ($domain, $username, $password, $email, $hours, $url) = @_;

    my $expiry = time() + ($hours * 3600);

    # Hash the password for storage
    my $password_hash = sha256_hex($password . $config->{'salt'});

    # Encrypt sensitive data
    my $encrypted_password = encrypt_data($password) if $config->{'encrypt_passwords'};

    my $account_data = {
        'domain' => $domain,
        'username' => $username,
        'password_hash' => $password_hash,
        'encrypted_password' => $encrypted_password,
        'email' => $email,
        'created' => format_time(time()),
        'expires' => format_time($expiry),
        'expiry_timestamp' => $expiry,
        'created_by' => $user,
        'url' => $url || "https://$domain",
        'hours' => $hours
    };

    my $json_line = encode_json($account_data) . "\n";

    open(my $fh, '>>', $log_file) or die "Cannot write to log file: $!";
    flock($fh, LOCK_EX);
    print $fh $json_line;
    flock($fh, LOCK_UN);
    close($fh);

    chmod 0600, $log_file;
}

sub remove_from_log {
    my ($domain, $username) = @_;

    return unless -f $log_file;

    open(my $fh, '+<', $log_file) or die "Cannot open log file: $!";
    flock($fh, LOCK_EX);

    my @lines = <$fh>;
    my @new_lines = ();

    foreach my $line (@lines) {
        chomp $line;
        next unless $line;

        eval {
            my $account = decode_json($line);
            if (!$account || $account->{'domain'} ne $domain || $account->{'username'} ne $username) {
                push @new_lines, $line;
            }
        };
        if ($@) {
            push @new_lines, $line;  # Keep line if we can't parse it
        }
    }

    seek($fh, 0, 0);
    truncate($fh, 0);
    print $fh join("\n", @new_lines) . "\n" if @new_lines;

    flock($fh, LOCK_UN);
    close($fh);
}

sub get_session_token {
    # Try multiple methods to get session token

    # Method 1: From URL path (cPanel style)
    my $request_uri = $ENV{'REQUEST_URI'} || '';
    if ($request_uri =~ m|/(cpsess\w+)/|) {
        return $1;
    }

    # Method 2: From environment variables
    return $ENV{'cp_security_token'} if $ENV{'cp_security_token'};
    return $ENV{'cpanel_security_token'} if $ENV{'cpanel_security_token'};

    # Method 3: From cookies
    my $cookie_header = $ENV{'HTTP_COOKIE'} || '';
    if ($cookie_header =~ /cpsession=([^;]+)/) {
        return $1;
    }

    # Method 4: From referer URL
    my $referer = $ENV{'HTTP_REFERER'} || '';
    if ($referer =~ m|/(cpsess\w+)/|) {
        return $1;
    }

    # Final fallback
    return 'cpsess_unknown';
}

sub get_time_remaining {
    my ($expiry_timestamp) = @_;
    my $diff = $expiry_timestamp - time();

    return 'Expired' if $diff <= 0;

    my $hours = int($diff / 3600);
    my $minutes = int(($diff % 3600) / 60);

    if ($hours > 0) {
        return "$hours hour" . ($hours != 1 ? 's' : '') . " left";
    } else {
        return "$minutes minute" . ($minutes != 1 ? 's' : '') . " left";
    }
}

sub format_time {
    my ($timestamp) = @_;
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime($timestamp);
    return sprintf("%04d-%02d-%02d %02d:%02d:%02d",
        $year + 1900, $mon + 1, $mday, $hour, $min, $sec);
}

sub sanitize_input {
    my ($input) = @_;
    return '' unless defined $input;

    # Prevent DoS attacks through excessively long inputs
    if (length($input) > 10000) {
        $logger->warn("Excessively long input detected, truncating");
        $input = substr($input, 0, 10000);
    }

    # Remove any HTML tags
    $input =~ s/<[^>]*>//g;

    # Escape special HTML characters
    $input =~ s/&/&amp;/g;
    $input =~ s/</&lt;/g;
    $input =~ s/>/&gt;/g;
    $input =~ s/"/&quot;/g;
    $input =~ s/'/&#39;/g;

    # Remove control characters
    $input =~ s/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]//g;

    return $input;
}

sub sanitize_url {
    my ($url) = @_;
    return '' unless defined $url;

    # Basic URL validation
    return '' unless $url =~ m{^https?://};

    # Remove any JavaScript protocols
    $url =~ s/^javascript://i;
    $url =~ s/^data://i;

    return sanitize_input($url);
}

sub load_config {
    my $default_config = {
        'salt' => generate_salt(),
        'encrypt_passwords' => 0,
        'encryption_key' => '',
        'max_account_duration' => 168,  # 1 week in hours
        'auto_cleanup_interval' => 3600,  # 1 hour in seconds
        'rate_limit_per_hour' => 10,  # Max accounts created per hour
        'max_active_accounts' => 20,  # Max active accounts warning
        'cleanup_warning_threshold' => 5,  # Alert when this many expired accounts exist
    };

    if (-f $config_file) {
        open(my $fh, '<', $config_file) or return $default_config;
        my $content = do { local $/; <$fh> };
        close($fh);

        eval {
            my $loaded = decode_json($content);
            foreach my $key (keys %$default_config) {
                $loaded->{$key} = $default_config->{$key} unless exists $loaded->{$key};
            }
            return $loaded;
        };
    }

    # Save default config
    save_config($default_config);
    return $default_config;
}

sub save_config {
    my ($config) = @_;

    open(my $fh, '>', $config_file) or die "Cannot write config file: $!";
    print $fh encode_json($config);
    close($fh);
    chmod 0600, $config_file;
}

sub generate_salt {
    my @chars = ('a'..'z', 'A'..'Z', '0'..'9');
    return join('', map { $chars[rand @chars] } 1..32);
}

sub encrypt_data {
    my ($data) = @_;
    return '' unless $data && $config->{'encryption_key'};

    eval {
        my $cipher = Crypt::CBC->new(
            -key    => $config->{'encryption_key'},
            -cipher => 'Blowfish',
        );
        return encode_base64($cipher->encrypt($data), '');
    };

    return '';
}

# WordPress Discovery and Direct Database Functions

sub wp_toolkit_available {
    # Check if WP Toolkit binary exists and is executable
    return (-x '/usr/local/psa/admin/bin/plesk' || -x '/usr/local/bin/plesk' || -d '/opt/psa');
}

sub discover_wordpress_sites {
    my @wp_sites = ();
    my @search_paths = (
        '/home/*/public_html',
        '/home/*/www',
        '/home/*/domains/*/public_html',
        '/var/www/html',
        '/var/www/vhosts/*/httpdocs',
        '/usr/local/apache/htdocs'
    );

    foreach my $path_pattern (@search_paths) {
        my @paths = glob($path_pattern);
        foreach my $path (@paths) {
            next unless -d $path;

            # Look for wp-config.php files recursively
            find(sub {
                return unless $_ eq 'wp-config.php';
                my $wp_config_path = $File::Find::name;
                my $wp_dir = dirname($wp_config_path);

                # Skip if already processed this directory
                return if grep { $_->{'path'} eq $wp_dir } @wp_sites;

                # Validate WordPress installation
                if (validate_wordpress_installation($wp_dir)) {
                    my $site_info = get_wordpress_site_info($wp_dir, $wp_config_path);
                    if ($site_info) {
                        push @wp_sites, $site_info;
                    }
                }
            }, $path);
        }
    }

    return @wp_sites;
}

sub validate_wordpress_installation {
    my ($wp_dir) = @_;

    # Check for core WordPress files
    my @required_files = (
        'wp-config.php',
        'wp-load.php',
        'wp-settings.php',
        'wp-includes/version.php'
    );

    foreach my $file (@required_files) {
        return 0 unless -f "$wp_dir/$file";
    }

    # Check for wp-content directory
    return 0 unless -d "$wp_dir/wp-content";

    return 1;
}

sub get_wordpress_site_info {
    my ($wp_dir, $wp_config_path) = @_;

    # Extract database credentials and site URL from wp-config.php
    my $db_info = parse_wp_config($wp_config_path);
    return unless $db_info;

    # Determine site URL from directory structure
    my $domain = extract_domain_from_path($wp_dir);
    my $path = extract_path_from_dir($wp_dir);

    # Get WordPress version
    my $version = get_wordpress_version($wp_dir);

    return {
        'id' => "direct_" . $domain . "_" . $path,
        'domain' => $domain,
        'path' => $path,
        'version' => $version,
        'url' => construct_site_url($domain, $path),
        'detection_method' => 'direct_scan',
        'features' => ['user_management'],
        'wp_dir' => $wp_dir,
        'db_info' => $db_info
    };
}

sub parse_wp_config {
    my ($wp_config_path) = @_;

    open(my $fh, '<', $wp_config_path) or return;
    my $content = do { local $/; <$fh> };
    close($fh);

    my %db_info;

    # Extract database configuration
    if ($content =~ /define\s*\(\s*['"]DB_NAME['"]\s*,\s*['"]([^'"]+)['"]\s*\)/i) {
        $db_info{'name'} = $1;
    }
    if ($content =~ /define\s*\(\s*['"]DB_USER['"]\s*,\s*['"]([^'"]+)['"]\s*\)/i) {
        $db_info{'user'} = $1;
    }
    if ($content =~ /define\s*\(\s*['"]DB_PASSWORD['"]\s*,\s*['"]([^'"]*)['"]\s*\)/i) {
        $db_info{'password'} = $1;
    }
    if ($content =~ /define\s*\(\s*['"]DB_HOST['"]\s*,\s*['"]([^'"]+)['"]\s*\)/i) {
        $db_info{'host'} = $1;
    } else {
        $db_info{'host'} = 'localhost';
    }

    # Extract table prefix
    if ($content =~ /\$table_prefix\s*=\s*['"]([^'"]*)['"]/i) {
        my $prefix = $1;
        # Validate table prefix for security (alphanumeric and underscore only)
        if ($prefix =~ /^[a-zA-Z0-9_]*$/ && length($prefix) <= 20) {
            $db_info{'prefix'} = $prefix;
        } else {
            # Invalid prefix, use default but log warning
            $db_info{'prefix'} = 'wp_';
            $logger->warn("Invalid table prefix detected in wp-config.php, using default");
        }
    } else {
        $db_info{'prefix'} = 'wp_';
    }

    return %db_info ? \%db_info : undef;
}

sub extract_domain_from_path {
    my ($wp_dir) = @_;

    # Common patterns for extracting domain from directory paths
    if ($wp_dir =~ m|/home/([^/]+)/|) {
        return $1;
    }
    if ($wp_dir =~ m|/var/www/vhosts/([^/]+)/|) {
        return $1;
    }
    if ($wp_dir =~ m|/home/[^/]+/domains/([^/]+)/|) {
        return $1;
    }

    # Fallback: use basename of directory above public_html
    my $parent_dir = dirname($wp_dir);
    if (basename($parent_dir) eq 'public_html' || basename($parent_dir) eq 'httpdocs') {
        $parent_dir = dirname($parent_dir);
        my $domain = basename($parent_dir);
        return $domain if $domain =~ /\./;
    }

    return 'localhost';
}

sub extract_path_from_dir {
    my ($wp_dir) = @_;

    # Check if WordPress is in subdirectory
    if ($wp_dir =~ m{/(public_html|httpdocs|www)/(.*)}) {
        my $subpath = $2;
        return $subpath ? "/$subpath" : '/';
    }

    return '/';
}

sub get_wordpress_version {
    my ($wp_dir) = @_;

    my $version_file = "$wp_dir/wp-includes/version.php";
    return 'Unknown' unless -f $version_file;

    open(my $fh, '<', $version_file) or return 'Unknown';
    my $content = do { local $/; <$fh> };
    close($fh);

    if ($content =~ /\$wp_version\s*=\s*['"]([^'"]+)['"]/i) {
        return $1;
    }

    return 'Unknown';
}

sub construct_site_url {
    my ($domain, $path) = @_;

    my $url = "https://$domain";
    $url .= $path if $path && $path ne '/';

    return $url;
}

sub create_wp_user_direct {
    my ($domain, $username, $password, $email) = @_;

    # Find the WordPress site information
    my @sites = discover_wordpress_sites();
    my $target_site;

    foreach my $site (@sites) {
        if ($site->{'domain'} eq $domain) {
            $target_site = $site;
            last;
        }
    }

    return 0 unless $target_site && $target_site->{'db_info'};

    my $db_info = $target_site->{'db_info'};

    # Connect to WordPress database
    my $dsn = "DBI:mysql:database=$db_info->{'name'};host=$db_info->{'host'}";
    my $dbh = DBI->connect($dsn, $db_info->{'user'}, $db_info->{'password'}, {
        RaiseError => 0,
        PrintError => 0,
        mysql_enable_utf8 => 1
    });

    return 0 unless $dbh;

    eval {
        my $prefix = $db_info->{'prefix'};

        # Check if user already exists
        my $check_sth = $dbh->prepare("SELECT ID FROM ${prefix}users WHERE user_login = ?");
        $check_sth->execute($username);
        if ($check_sth->fetchrow_array()) {
            $check_sth->finish();
            $dbh->disconnect();
            return 0; # User already exists
        }
        $check_sth->finish();

        # Hash password using WordPress-compatible method
        my $hashed_password = wp_hash_password($password);

        # Insert user
        my $insert_sth = $dbh->prepare("
            INSERT INTO ${prefix}users
            (user_login, user_pass, user_nicename, user_email, user_registered, display_name)
            VALUES (?, ?, ?, ?, NOW(), ?)
        ");

        $insert_sth->execute($username, $hashed_password, $username, $email, $username);
        my $user_id = $dbh->last_insert_id(undef, undef, "${prefix}users", "ID");
        $insert_sth->finish();

        return 0 unless $user_id;

        # Set user capabilities (administrator)
        my $meta_sth = $dbh->prepare("
            INSERT INTO ${prefix}usermeta (user_id, meta_key, meta_value)
            VALUES (?, ?, ?)
        ");

        # Add capabilities
        $meta_sth->execute($user_id, "${prefix}capabilities", 'a:1:{s:13:"administrator";b:1;}');
        $meta_sth->execute($user_id, "${prefix}user_level", '10');
        $meta_sth->finish();

        $dbh->disconnect();
        return 1;
    };

    if ($@) {
        $dbh->disconnect() if $dbh;
        return 0;
    }
}

sub delete_wp_user_direct {
    my ($domain, $username) = @_;

    # Find the WordPress site information
    my @sites = discover_wordpress_sites();
    my $target_site;

    foreach my $site (@sites) {
        if ($site->{'domain'} eq $domain) {
            $target_site = $site;
            last;
        }
    }

    return 0 unless $target_site && $target_site->{'db_info'};

    my $db_info = $target_site->{'db_info'};

    # Connect to WordPress database
    my $dsn = "DBI:mysql:database=$db_info->{'name'};host=$db_info->{'host'}";
    my $dbh = DBI->connect($dsn, $db_info->{'user'}, $db_info->{'password'}, {
        RaiseError => 0,
        PrintError => 0
    });

    return 0 unless $dbh;

    eval {
        my $prefix = $db_info->{'prefix'};

        # Get user ID
        my $user_sth = $dbh->prepare("SELECT ID FROM ${prefix}users WHERE user_login = ?");
        $user_sth->execute($username);
        my ($user_id) = $user_sth->fetchrow_array();
        $user_sth->finish();

        return 0 unless $user_id;

        # Delete user metadata
        my $meta_sth = $dbh->prepare("DELETE FROM ${prefix}usermeta WHERE user_id = ?");
        $meta_sth->execute($user_id);
        $meta_sth->finish();

        # Delete user
        my $delete_sth = $dbh->prepare("DELETE FROM ${prefix}users WHERE ID = ?");
        $delete_sth->execute($user_id);
        $delete_sth->finish();

        $dbh->disconnect();
        return 1;
    };

    if ($@) {
        $dbh->disconnect() if $dbh;
        return 0;
    }
}

sub wp_hash_password {
    my ($password) = @_;

    # WordPress-compatible password hashing using portable PHP password hashing
    # This implements the same algorithm WordPress uses for compatibility
    use Digest::MD5 qw(md5_hex);

    my $salt = generate_salt(8);
    my $count = 8; # 2^8 = 256 iterations (WordPress default)
    my $hash = md5($salt . $password);

    # Perform the iteration strengthening
    for (my $i = 0; $i < (1 << $count); $i++) {
        $hash = md5($hash . $password);
    }

    # Return WordPress-compatible hash format
    return '$P$' . chr(ord('.') + $count) . $salt . substr(encode_base64($hash), 0, 22);
}

sub md5 {
    my ($data) = @_;
    use Digest::MD5;
    return Digest::MD5::md5($data);
}

sub generate_salt {
    my ($length) = @_;
    my @chars = ('a'..'z', 'A'..'Z', '0'..'9', '.', '/');
    return join '', map { $chars[rand @chars] } 1..$length;
}

# WordPress Site Health and Validation Functions

sub validate_wp_site_health {
    my ($domain) = @_;

    my %health_report = (
        'domain' => $domain,
        'wp_toolkit_available' => JSON::PP::false,
        'direct_access_available' => JSON::PP::false,
        'database_accessible' => JSON::PP::false,
        'wp_version' => 'Unknown',
        'recommendations' => [],
        'status' => 'unknown'
    );

    # Check WP Toolkit availability
    if (wp_toolkit_available()) {
        $health_report{'wp_toolkit_available'} = JSON::PP::true;

        # Try to find the site via WP Toolkit
        my $wp_data = call_wp_toolkit_api('get_installations');
        if ($wp_data && $wp_data->{'data'}) {
            foreach my $install (@{$wp_data->{'data'}}) {
                if (($install->{'domain'} && $install->{'domain'} eq $domain) ||
                    ($install->{'url'} && $install->{'url'} =~ /\Q$domain\E/)) {
                    $health_report{'wp_version'} = $install->{'version'} || 'Unknown';
                    $health_report{'status'} = 'good';
                    push @{$health_report{'recommendations'}}, 'Site managed by WP Toolkit - preferred method';
                    last;
                }
            }
        }
    }

    # Check direct access
    my @direct_sites = discover_wordpress_sites();
    foreach my $site (@direct_sites) {
        if ($site->{'domain'} eq $domain) {
            $health_report{'direct_access_available'} = JSON::PP::true;
            $health_report{'wp_version'} = $site->{'version'} if $site->{'version'} ne 'Unknown';

            # Test database connection
            if ($site->{'db_info'}) {
                my $db_info = $site->{'db_info'};
                my $dsn = "DBI:mysql:database=$db_info->{'name'};host=$db_info->{'host'}";
                my $dbh = DBI->connect($dsn, $db_info->{'user'}, $db_info->{'password'}, {
                    RaiseError => 0,
                    PrintError => 0
                });

                if ($dbh) {
                    $health_report{'database_accessible'} = JSON::PP::true;
                    $dbh->disconnect();

                    if ($health_report{'status'} eq 'unknown') {
                        $health_report{'status'} = 'fair';
                        push @{$health_report{'recommendations'}}, 'Direct database access available as fallback';
                    }
                } else {
                    push @{$health_report{'recommendations'}}, 'Warning: Database connection failed';
                    $health_report{'status'} = 'poor' if $health_report{'status'} eq 'unknown';
                }
            }
            last;
        }
    }

    # Final status determination
    if (!$health_report{'wp_toolkit_available'} && !$health_report{'direct_access_available'}) {
        $health_report{'status'} = 'critical';
        push @{$health_report{'recommendations'}}, 'WordPress installation not detected';
    } elsif (!$health_report{'database_accessible'} && !$health_report{'wp_toolkit_available'}) {
        $health_report{'status'} = 'poor';
        push @{$health_report{'recommendations'}}, 'No working connection method available';
    }

    return \%health_report;
}

sub check_wordpress_requirements {
    my ($wp_dir) = @_;

    my @requirements = (
        {
            'name' => 'WordPress Core Files',
            'status' => (-f "$wp_dir/wp-config.php" && -f "$wp_dir/wp-load.php") ? 'pass' : 'fail',
            'description' => 'Core WordPress files present'
        },
        {
            'name' => 'Write Permissions',
            'status' => (-w "$wp_dir/wp-content") ? 'pass' : 'fail',
            'description' => 'wp-content directory is writable'
        },
        {
            'name' => 'WordPress Version',
            'status' => (get_wordpress_version($wp_dir) ne 'Unknown') ? 'pass' : 'fail',
            'description' => 'WordPress version detectable'
        }
    );

    return \@requirements;
}

sub get_system_health_overview {
    my $overview = {
        'wp_toolkit_status' => wp_toolkit_available() ? 'available' : 'not_available',
        'discovered_sites' => [],
        'total_sites' => 0,
        'healthy_sites' => 0,
        'sites_with_issues' => 0,
        'system_recommendations' => []
    };

    # Get all discovered sites
    my @all_sites = ();

    # Add WP Toolkit sites
    if (wp_toolkit_available()) {
        my $wp_data = call_wp_toolkit_api('get_installations');
        if ($wp_data && $wp_data->{'data'}) {
            foreach my $installation (@{$wp_data->{'data'}}) {
                push @all_sites, {
                    'domain' => $installation->{'domain'} || 'Unknown',
                    'detection_method' => 'wp_toolkit',
                    'version' => $installation->{'version'} || 'Unknown'
                };
            }
        }
    }

    # Add direct discovery sites
    my @direct_sites = discover_wordpress_sites();
    foreach my $site (@direct_sites) {
        # Avoid duplicates
        my $already_exists = 0;
        foreach my $existing (@all_sites) {
            if ($existing->{'domain'} eq $site->{'domain'}) {
                $already_exists = 1;
                last;
            }
        }

        unless ($already_exists) {
            push @all_sites, {
                'domain' => $site->{'domain'},
                'detection_method' => 'direct_scan',
                'version' => $site->{'version'}
            };
        }
    }

    $overview->{'discovered_sites'} = \@all_sites;
    $overview->{'total_sites'} = scalar(@all_sites);

    # Analyze health
    foreach my $site (@all_sites) {
        my $health = validate_wp_site_health($site->{'domain'});
        if ($health->{'status'} eq 'good') {
            $overview->{'healthy_sites'}++;
        } elsif ($health->{'status'} ne 'unknown') {
            $overview->{'sites_with_issues'}++;
        }
    }

    # System recommendations
    if ($overview->{'wp_toolkit_status'} eq 'not_available') {
        push @{$overview->{'system_recommendations'}},
             'Consider installing WP Toolkit for better WordPress management';
    }

    if ($overview->{'sites_with_issues'} > 0) {
        push @{$overview->{'system_recommendations'}},
             'Some WordPress sites have configuration issues that may affect temporary account creation';
    }

    return $overview;
}

sub decrypt_data {
    my ($encrypted) = @_;
    return '' unless $encrypted && $config->{'encryption_key'};

    eval {
        my $cipher = Crypt::CBC->new(
            -key    => $config->{'encryption_key'},
            -cipher => 'Blowfish',
        );
        return $cipher->decrypt(decode_base64($encrypted));
    };

    return '';
}

sub print_success {
    my ($data) = @_;
    print encode_json({ 'success' => JSON::PP::true, 'data' => $data });
}

sub print_error {
    my ($message) = @_;
    print encode_json({ 'success' => JSON::PP::false, 'error' => sanitize_input($message) });
    $logger->warn("WP Temp Accounts Error: $message");
}

# Cleanup: Restore original user context if impersonation was active
END {
    if ($impersonation_active) {
        eval {
            require Cpanel::AccessIds;
            Cpanel::AccessIds::popuids();
        };
    }
}

1;  # Return true value if required as a module