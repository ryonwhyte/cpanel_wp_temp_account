# WP Temporary Accounts - WHM Plugin

A secure WHM plugin for creating and managing temporary WordPress administrator accounts with automatic cleanup functionality. **This is a WHM plugin designed for system administrators.**

## Features

### Core Functionality
- ✅ Create temporary WordPress admin accounts with customizable expiration times
- ✅ Automatic cleanup of expired accounts via cron jobs
- ✅ **Universal Compatibility**: Works with WP Toolkit OR direct WordPress installations
- ✅ **Hybrid Detection**: Automatically detects WordPress sites via WP Toolkit and direct filesystem scanning
- ✅ **Intelligent Fallback**: Uses WP Toolkit when available, falls back to direct database access
- ✅ User-friendly web interface integrated with cPanel/WHM
- ✅ Detailed account tracking and management
- ✅ One-click login URL generation
- ✅ **NEW**: Real-time dashboard with statistics and alerts
- ✅ **NEW**: Activity tracking and audit logs
- ✅ **NEW**: Advanced table filtering and sorting
- ✅ **NEW**: Site-based account statistics
- ✅ **NEW**: WordPress site health validation and monitoring

### Security Features
- 🔒 **CSRF Protection**: All state-changing operations require valid CSRF tokens
- 🔒 **Input Validation**: Comprehensive input sanitization and validation
- 🔒 **XSS Protection**: All user data is properly escaped before display
- 🔒 **Command Injection Prevention**: Uses LWP::UserAgent instead of shell commands
- 🔒 **Secure Password Generation**: 20-character passwords with mixed case, numbers, and symbols
- 🔒 **Password Hashing**: Passwords are hashed in logs (optional encryption available)
- 🔒 **File Permissions**: Secure file permissions (600) for sensitive data
- 🔒 **NEW**: Rate limiting (10 accounts per hour by default)
- 🔒 **NEW**: Honeypot protection against bots
- 🔒 **NEW**: Suspicious behavior detection and auto-suspension
- 🔒 **NEW**: Activity monitoring with IP tracking

### Monitoring & Alerts
- 📊 **Real-time Dashboard**: Overview cards showing active accounts, daily statistics
- 🚨 **Smart Alerts**: Warnings for high account usage, cleanup needed, expired accounts
- 📈 **Site Statistics**: Visual charts showing account distribution by site
- 📝 **Activity Feed**: Real-time log of all account operations
- ⚠️ **Health Monitoring**: Automatic alerts if cleanup hasn't run or too many accounts exist

## Requirements

- cPanel/WHM with Paper Lantern theme
- Perl 5.10 or higher
- Root access for installation
- **WordPress Requirements**:
  - Option A: WP Toolkit installed and configured (preferred)
  - Option B: Direct filesystem access to WordPress installations
  - MySQL/MariaDB database access for WordPress sites

### Required Perl Modules
- CGI
- JSON::PP
- LWP::UserAgent
- HTTP::Request
- URI::Escape
- Digest::SHA
- MIME::Base64
- Crypt::CBC (for encryption features)
- DBI (for direct database access)
- DBD::mysql (for MySQL/MariaDB connectivity)
- File::Find (for WordPress discovery)
- File::Basename (for path handling)
- Time::Local
- Fcntl
- File::Path
- Cpanel::Logger

## Installation

### WHM Plugin Installation (Recommended)

1. Clone or download this repository to your server:
```bash
git clone https://github.com/ryonwhyte/cpanel_wp_temp_account.git
cd cpanel_wp_temp_account
```

2. Install as WHM plugin (as root):
```bash
./install_whm.sh
```

The installer will:
- Create WHM plugin directories
- Install CGI script with proper WHM registration
- Copy Template Toolkit files for WHM integration
- Install 48x48 PNG icon for menu display
- Set up automatic cleanup via cron
- Configure proper permissions

### Access the Plugin

After installation, access via:
- **WHM Interface:** Plugins → WP Temporary Accounts
- **Direct URL:** `https://your-server:2087/cgi/wp_temp_accounts/wp_temp_accounts.cgi`

### Troubleshooting

If the plugin doesn't appear in WHM:

1. **Check AppConfig registration**:
```bash
cat /var/cpanel/apps/wp_temp_accounts.conf
```

2. **Verify CGI file**:
```bash
ls -la /usr/local/cpanel/whostmgr/docroot/cgi/wp_temp_accounts/
```

3. **Restart cpsrvd**:
```bash
/scripts/restartsrv_cpsrvd
```

## Usage

### Accessing the Plugin

After installation, system administrators can access the plugin through:
- **WHM Interface**: Navigate to Plugins → WP Temporary Accounts
- **Direct URL**: `https://your-server:2087/cgi/wp_temp_accounts/wp_temp_accounts.cgi`

### Creating Temporary Accounts

1. Select a WordPress site from the dropdown
2. Choose an expiration time (1 hour to 1 week)
3. Click "Create Temporary Account"
4. Save the generated credentials (they won't be shown again)

### Managing Accounts

- **View Active Accounts**: See all active temporary accounts with expiration times
- **Delete Accounts**: Manually remove accounts before expiration
- **Cleanup Expired**: Remove all expired accounts at once
- **Auto-refresh**: Account list refreshes every 30 seconds

## Configuration

Configuration file location: `~/.wp_temp_accounts/config.json`

### Default Configuration
```json
{
    "salt": "random_32_char_string",
    "encrypt_passwords": false,
    "encryption_key": "",
    "max_account_duration": 168,
    "auto_cleanup_interval": 3600
}
```

### Configuration Options

- **salt**: Random string used for password hashing (auto-generated)
- **encrypt_passwords**: Enable password encryption in logs (requires encryption_key)
- **encryption_key**: Key for password encryption (must be set if encryption is enabled)
- **max_account_duration**: Maximum account duration in hours (default: 168 = 1 week)
- **auto_cleanup_interval**: Cleanup check interval in seconds (default: 3600 = 1 hour)

## File Structure

```
/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account/
├── cpanel_wp_temp_account.pl      # Backend Perl script
├── cpanel_wp_temp_account.js      # Frontend JavaScript
├── cpanel_wp_temp_account.html    # HTML interface
├── cpanel_wp_temp_account.css     # Styles
├── plugin.json                    # Plugin metadata
└── uninstall.sh                   # Uninstall script

~/.wp_temp_accounts/               # User data directory
├── config.json                   # Configuration file
├── accounts.log                   # Active accounts log
└── .csrf_tokens                 # CSRF token storage
```

## API Endpoints

All API calls are made to `cpanel_wp_temp_account.pl` with POST requests.

### Available Actions

#### Get CSRF Token
```javascript
action: 'get_csrf_token'
```

#### List WordPress Sites
```javascript
action: 'get_wp_sites'
```

#### Create Temporary Account
```javascript
action: 'create_temp_account'
domain: 'example.com'
hours: 24
csrf_token: 'valid_token'
```

#### List Active Accounts
```javascript
action: 'list_temp_accounts'
```

#### Delete Account
```javascript
action: 'delete_account'
domain: 'example.com'
username: 'temp_admin_xxx'
csrf_token: 'valid_token'
```

#### Cleanup Expired Accounts
```javascript
action: 'cleanup_expired'
csrf_token: 'valid_token'
```

#### Validate Site Health
```javascript
action: 'validate_site_health'
domain: 'example.com'
```

#### Get System Health Overview
```javascript
action: 'get_system_health'
```

## WordPress Compatibility

### Hybrid Detection System

This plugin uses a sophisticated hybrid detection system that ensures compatibility with virtually any WordPress installation:

#### Method 1: WP Toolkit (Preferred)
- **Automatic detection** of WP Toolkit managed sites
- **Native integration** with cPanel's WordPress management
- **Enhanced features** like staging and security scanning
- **Indicator**: 🛠️ WP Toolkit

#### Method 2: Direct Discovery (Fallback)
- **Filesystem scanning** for wp-config.php files
- **Direct database access** for user management
- **Universal compatibility** with any WordPress installation
- **Indicator**: 🔍 Direct Database

### Supported WordPress Configurations

- ✅ **Standard installations** in public_html directories
- ✅ **Subdirectory installations** (domain.com/wordpress)
- ✅ **Subdomain installations** (blog.domain.com)
- ✅ **Multiple domains** per cPanel account
- ✅ **Custom directory structures**
- ✅ **Shared hosting environments**
- ✅ **VPS and dedicated server installations**

### WordPress Discovery Locations

The plugin automatically scans these common paths:
- `/home/*/public_html`
- `/home/*/www`
- `/home/*/domains/*/public_html`
- `/var/www/html`
- `/var/www/vhosts/*/httpdocs`
- `/usr/local/apache/htdocs`

### Database Requirements

For direct database access, the plugin requires:
- **MySQL/MariaDB** database connectivity
- **Database credentials** accessible via wp-config.php
- **Standard WordPress** table structure
- **wp_users and wp_usermeta** tables present

## Security Considerations

### Best Practices

1. **Regular Updates**: Keep the plugin updated with the latest security patches
2. **Access Control**: Limit access to trusted administrators only
3. **Monitor Logs**: Regularly review account creation and deletion logs
4. **Cleanup Schedule**: Ensure automatic cleanup is functioning properly
5. **Strong Passwords**: The plugin generates 20-character random passwords by default

### Security Features in Detail

#### CSRF Protection
- All state-changing operations require valid CSRF tokens
- Tokens expire after 1 hour
- New tokens are generated for each session

#### Input Validation
- Domain names are validated against regex patterns
- Expiration times are limited to 1-168 hours
- All user inputs are sanitized before processing

#### XSS Prevention
- All output is HTML-escaped using a secure escaping function
- URLs are validated and sanitized
- Content Security Policy headers recommended

## Troubleshooting

### Common Issues

#### "WP Toolkit not found"
- Ensure WP Toolkit is installed: `/scripts/install_plugin wp-toolkit`

#### "Failed to create WordPress user"
- Check WP Toolkit API is accessible
- Verify the WordPress installation is managed by WP Toolkit
- Check cPanel error logs: `/usr/local/cpanel/logs/error_log`

#### "Invalid CSRF token"
- Clear browser cache and cookies
- Reload the page to get a new token
- Check system time is correct

#### Missing Perl Modules
Install missing modules using cpanm:
```bash
/usr/local/cpanel/3rdparty/bin/cpanm Module::Name
```

### Log Files

- **Plugin logs**: `~/.wp_temp_accounts/accounts.log`
- **cPanel logs**: `/usr/local/cpanel/logs/error_log`
- **Apache logs**: `/usr/local/apache/logs/error_log`

## Uninstallation

### Standard Uninstall
Run the uninstall script:
```bash
./uninstall_whm.sh
```

### Complete Cleanup (if needed)
For a thorough cleanup that removes ALL traces:
```bash
./complete_cleanup.sh
```

This comprehensive cleanup script will:
- Remove all plugin files from all possible locations
- Clear all WHM caches
- Remove cron jobs
- Optionally remove user data
- Restart WHM services
- Provide browser cleanup instructions

## Development

### Testing
```bash
# Test the Perl backend
perl -c cpanel_wp_temp_account.pl

# Check for syntax errors in JavaScript
jshint cpanel_wp_temp_account.js
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Version History

### Version 3.0 (Universal)
- **Universal WordPress Compatibility**: Removed WP Toolkit dependency
- **Hybrid Detection System**: WP Toolkit preferred, direct database as fallback
- **WordPress Site Discovery**: Automatic filesystem scanning for wp-config.php
- **Direct Database Integration**: Native WordPress user creation/deletion via DBI
- **Health Monitoring**: WordPress site validation and system health checks
- **Enhanced UI**: Visual indicators for detection methods (🛠️/🔍)
- **Improved Security**: WordPress-compatible password hashing
- **Better Error Handling**: Graceful fallbacks for all operations

### Version 2.0 (Secure)
- Added CSRF protection
- Fixed command injection vulnerability
- Implemented comprehensive input validation
- Added XSS protection
- Replaced deprecated modules
- Enhanced error handling
- Added configuration file support
- Improved password security

### Version 1.0 (Original)
- Initial release
- Basic temporary account creation
- Manual and automatic cleanup
- Web interface

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### What this means:
- ✅ **Free to use** for personal and commercial projects
- ✅ **Free to modify** and customize for your needs
- ✅ **Free to distribute** and share with others
- ✅ **No warranty** - use at your own risk
- ⚠️ **Attribution required** - keep the copyright notice

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Contact support at [your-email@example.com]

## Acknowledgments

- Built for cPanel/WHM environments
- Integrates with WP Toolkit API
- Uses Paper Lantern theme standards

---

**Security Notice**: This plugin creates WordPress administrator accounts. Ensure proper access controls and monitoring are in place.