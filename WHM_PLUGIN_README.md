# WHM Plugin Installation for WP Temporary Accounts

## 🎯 **IMPORTANT DISCOVERY**

We discovered that this should be installed as a **WHM Plugin** rather than a cPanel plugin. WHM plugins appear in the WHM interface and are accessible to system administrators.

## 📋 **WHM Plugin Files**

### **Essential Files:**
- `wp_temp_accounts.conf` - AppConfig configuration for WHM registration
- `wp_temp_accounts.cgi` - WHM CGI entry point
- `install_whm.sh` - Official WHM plugin installer
- `uninstall_whm.sh` - WHM plugin uninstaller
- `create_icon.sh` - Icon creation helper

### **Core Plugin Files** (same as before):
- `cpanel_wp_temp_account.pl` - Backend logic
- `cpanel_wp_temp_account.js` - Frontend JavaScript
- `cpanel_wp_temp_account.html` - Interface
- `cpanel_wp_temp_account.css` - Styles

## 🚀 **Installation as WHM Plugin**

### **Step 1: Install the WHM Plugin**
```bash
# Run the WHM plugin installer
./install_whm.sh
```

### **Step 2: Create the Icon (Required)**
```bash
# Create the 48x48 PNG icon for WHM
./create_icon.sh
```

### **Step 3: Verify Installation**
The plugin should appear in:
- **WHM → Plugins → WP Temporary Accounts**
- **Direct URL:** `https://your-server:2087/cgi/wp_temp_accounts/wp_temp_accounts.cgi`

## 📁 **WHM Plugin Structure (After Installation)**

```
/usr/local/cpanel/whostmgr/docroot/cgi/wp_temp_accounts/
  └── wp_temp_accounts.cgi                    # Main CGI entry point

/usr/local/cpanel/whostmgr/docroot/templates/wp_temp_accounts/
  ├── index.tmpl                              # Main interface template
  ├── style.css                               # Stylesheet
  └── script.js                               # JavaScript

/usr/local/cpanel/whostmgr/docroot/addon_plugins/
  └── wp_temp_accounts_icon.png               # 48x48 PNG icon

/var/cpanel/apps/
  └── wp_temp_accounts.conf                   # AppConfig registration
```

## 🔧 **How WHM Plugin Registration Works**

### **AppConfig System:**
1. **Configuration File:** `wp_temp_accounts.conf` defines the plugin
2. **Registration Command:** `/usr/local/cpanel/bin/register_appconfig`
3. **Result:** Plugin appears in WHM Plugins section

### **AppConfig File Format:**
```ini
service=whostmgr
url=/cgi/wp_temp_accounts/wp_temp_accounts.cgi
acls=all
entryurl=addons/wp_temp_accounts/index.cgi
displayname=WP Temporary Accounts
icon=wp_temp_accounts_icon.png
target=_self
group=plugins
```

## 🔍 **Troubleshooting WHM Plugin**

### **Plugin Doesn't Appear in WHM:**
1. **Check AppConfig registration:**
   ```bash
   cat /var/cpanel/apps/wp_temp_accounts.conf
   ```

2. **Verify CGI file exists:**
   ```bash
   ls -la /usr/local/cpanel/whostmgr/docroot/cgi/wp_temp_accounts/
   ```

3. **Test direct URL:**
   ```
   https://your-server:2087/cgi/wp_temp_accounts/wp_temp_accounts.cgi
   ```

4. **Restart cpsrvd:**
   ```bash
   /scripts/restartsrv_cpsrvd
   ```

### **Icon Not Appearing:**
Create a 48x48 PNG icon:
```bash
./create_icon.sh
```

### **Permission Issues:**
```bash
chmod 755 /usr/local/cpanel/whostmgr/docroot/cgi/wp_temp_accounts/wp_temp_accounts.cgi
```

## 📚 **WHM vs cPanel Plugin Differences**

| Aspect | cPanel Plugin | WHM Plugin |
|--------|---------------|------------|
| **Access** | End users | System administrators |
| **Location** | `/frontend/paper_lantern/` | `/whostmgr/docroot/cgi/` |
| **Registration** | `.cpanelplugin` file | AppConfig system |
| **Icon** | SVG/CSS | 48x48 PNG |
| **Interface** | cPanel Software section | WHM Plugins section |
| **Permissions** | User-level | Administrator-level |

## 🎯 **Key Benefits of WHM Plugin**

1. **Proper Integration:** Uses official cPanel AppConfig registration
2. **Administrator Access:** Appropriate for account management functionality
3. **Official Support:** Follows cPanel's documented plugin development process
4. **Better Visibility:** Appears reliably in WHM Plugins section
5. **Cleaner Architecture:** Separates admin tools from user tools

## 🚀 **Next Steps**

1. **Run the WHM installer:** `./install_whm.sh`
2. **Create the icon:** `./create_icon.sh`
3. **Access via WHM:** Plugins → WP Temporary Accounts
4. **Test functionality:** Create/manage temporary accounts

This approach follows cPanel's official documentation and should provide reliable plugin registration and visibility in the WHM interface.