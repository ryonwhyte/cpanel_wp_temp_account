# WP Temporary Accounts Plugin - Complete Installation Guide

## 🚀 **Best Solution Implementation**

This guide provides the complete, production-ready solution for installing and registering the WP Temporary Accounts plugin with cPanel/WHM.

## 📋 **What's Included**

### **Core Plugin Files**
- `cpanel_wp_temp_account.pl` - Secure Perl backend
- `cpanel_wp_temp_account.js` - Enhanced JavaScript frontend
- `cpanel_wp_temp_account.html` - Responsive HTML interface
- `cpanel_wp_temp_account.css` - Modern stylesheet

### **Installation & Registration**
- `install.sh` - ✅ **Enhanced installation script with auto module installation**
- `register_plugin.sh` - ✅ **Comprehensive cPanel registration**
- `feature_registration.sh` - Alternative registration method

### **Visual Integration**
- `icon.svg` - ✅ **Professional SVG icon**
- `icon.css` - ✅ **CSS-based icon for cPanel interface**
- `cpanel_integration.conf` - Complete integration configuration

### **Documentation**
- `INSTALLATION_GUIDE.md` - This guide
- `README.md` - Comprehensive plugin documentation

## 🛠️ **Installation Methods**

### **Method 1: Automatic Installation (Recommended)**
```bash
# Standard installation
./install.sh

# Automated installation (no prompts)
./install.sh --force

# Skip Perl module installation
./install.sh --skip-modules

# Get help
./install.sh --help
```

### **Method 2: Manual Registration (If plugin doesn't appear)**
```bash
# Run comprehensive registration
./register_plugin.sh
```

### **Method 3: Alternative Registration**
```bash
# Alternative registration method
./feature_registration.sh
```

## 🔧 **Installation Features**

### **✅ Automatic Perl Module Installation**
The installer now tries multiple methods to install missing modules:

1. **cPanel cpanm** (most compatible)
2. **System cpanm** (if available)
3. **CPAN** (traditional installer)
4. **Package manager** (yum/dnf/apt for common modules)

**Supported modules:**
- `CGI` → Automatically installs via package manager
- `Crypt::CBC` → Automatically installs via package manager
- `Cpanel::Logger` → Available with cPanel (skipped)

### **✅ Professional Icon Integration**
- **WordPress-themed icon** with timer overlay
- **Multiple sizes** (16x16, 32x32, 48x48)
- **CSS-based rendering** for universal compatibility
- **Automatic sprite generation**

### **✅ Complete cPanel Integration**
- **Feature registration** with proper metadata
- **ACL permissions** for user access control
- **Category placement** in Software section
- **Help URL** and documentation links
- **Version tracking** and compatibility info

### **✅ Robust Error Handling**
- **Graceful degradation** if modules fail to install
- **Multiple registration fallbacks**
- **Clear error messages** with solution suggestions
- **Cache clearing** for immediate visibility

## 📍 **Plugin Locations After Installation**

### **Plugin Access**
- **cPanel Interface:** Software → WP Temporary Accounts
- **WHM Interface:** Plugins → WP Temporary Accounts

### **Direct URLs**
- **cPanel:** `https://your-domain:2083/frontend/paper_lantern/cpanel_wp_temp_account/cpanel_wp_temp_account.html`
- **WHM:** `https://your-server:2087/frontend/paper_lantern/cpanel_wp_temp_account/cpanel_wp_temp_account.html`

### **File Locations**
- **Plugin Directory:** `/usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account/`
- **Feature Config:** `/var/cpanel/apps/cpanel_wp_temp_account.conf`
- **User Data:** `~/.wp_temp_accounts/`
- **Cleanup Script:** `/usr/local/cpanel/scripts/cpanel_wp_temp_account_cleanup`

## 🔍 **Troubleshooting**

### **Plugin Doesn't Appear in Interface**
1. **Wait 1-2 minutes** for cPanel cache refresh
2. **Log out and log back in** to cPanel/WHM
3. **Try direct URL access** first
4. **Run manual registration:** `./register_plugin.sh`
5. **Check feature file exists:** `/var/cpanel/apps/cpanel_wp_temp_account.conf`

### **Perl Module Issues**
```bash
# Check module availability
perl -MCGI -e 'print "CGI available\n"'
perl -MCrypt::CBC -e 'print "Crypt::CBC available\n"'

# Manual installation
/usr/local/cpanel/3rdparty/bin/cpanm CGI Crypt::CBC
```

### **Permission Issues**
```bash
# Fix file permissions
chown -R cpanel:cpanel /usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account/
chmod 755 /usr/local/cpanel/base/frontend/paper_lantern/cpanel_wp_temp_account/cpanel_wp_temp_account.pl
```

### **Service Restart**
```bash
# Restart cPanel services
/scripts/restartsrv_cpsrvd
/usr/local/cpanel/bin/rebuild_sprites
```

## 🎯 **Key Improvements**

### **From Previous Versions:**
- ✅ **Automatic module installation** (no more manual dependency setup)
- ✅ **Professional icon** (proper visual integration)
- ✅ **Complete cPanel registration** (appears in interface reliably)
- ✅ **Multiple installation options** (interactive, automated, custom)
- ✅ **Robust error handling** (graceful failure recovery)
- ✅ **Comprehensive documentation** (clear installation steps)

### **Production Ready:**
- ✅ **Enterprise-grade security** (CSRF, XSS, injection protection)
- ✅ **Universal WordPress compatibility** (WP Toolkit + Direct Database)
- ✅ **Automatic cleanup** (cron-based expired account removal)
- ✅ **Real-time monitoring** (dashboard, health checks, alerts)
- ✅ **Professional presentation** (modern UI, proper icons, help system)

## 📞 **Support**

### **Installation Support**
- Check the installation output for specific error messages
- Review `/usr/local/cpanel/logs/error_log` for cPanel-specific issues
- Test direct URL access before troubleshooting interface visibility

### **Plugin Support**
- Plugin logs: `~/.wp_temp_accounts/accounts.log`
- cPanel error logs: `/usr/local/cpanel/logs/error_log`
- WordPress logs: Check individual site error logs

### **Documentation**
- **README.md** - Complete plugin functionality documentation
- **CLAUDE.md** - Detailed development history and architecture
- **GitHub Issues** - Report bugs and feature requests

---

## 🎉 **Installation Success!**

Your WP Temporary Accounts plugin is now properly installed with:
- ✅ Professional icon integration
- ✅ Automatic Perl module installation
- ✅ Complete cPanel interface registration
- ✅ Universal WordPress compatibility
- ✅ Enterprise-grade security features

**The plugin should now appear in your cPanel/WHM interface under the Software section!**