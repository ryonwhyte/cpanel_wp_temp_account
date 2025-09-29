# WP Temporary Accounts - WHM Plugin Structure

## 🎯 **Essential Files (WHM Plugin)**

### **Core Plugin Files**
```
cpanel_wp_temp_account.pl      # Backend Perl logic
cpanel_wp_temp_account.js      # Frontend JavaScript
cpanel_wp_temp_account.html    # User interface
cpanel_wp_temp_account.css     # Stylesheet
```

### **WHM Plugin Configuration**
```
wp_temp_accounts.conf          # AppConfig registration file
wp_temp_accounts.cgi           # WHM CGI entry point
```

### **Installation & Management**
```
install_whm.sh                 # WHM plugin installer
uninstall_whm.sh               # WHM plugin uninstaller
create_icon.sh                 # Icon creation helper
```

### **Visual Assets**
```
icon.svg                       # Source icon (SVG format)
icon.css                       # Icon styles (fallback)
```

### **Documentation**
```
README.md                      # Main project documentation
WHM_PLUGIN_README.md           # WHM plugin specific guide
CLAUDE.md                      # Development history
LICENSE                        # MIT License
PROJECT_STRUCTURE.md           # This file
```


## 🎯 **Current Focus: WHM Plugin**

The project has evolved from a cPanel user plugin to a **WHM administrator plugin** following cPanel's official documentation.

### **Key Benefits:**
- ✅ **Official AppConfig Registration** - Uses cPanel's documented method
- ✅ **Administrator Access** - Appropriate for account management
- ✅ **Reliable Integration** - Follows WHM plugin development standards
- ✅ **Clean Architecture** - Separates admin tools from user interface

### **Installation:**
```bash
./install_whm.sh              # Install WHM plugin
./create_icon.sh               # Create required icon
```

### **Access:**
- **WHM Interface:** Plugins → WP Temporary Accounts
- **Direct URL:** `https://server:2087/cgi/wp_temp_accounts/wp_temp_accounts.cgi`

## 🧹 **Cleanup Summary**

**Removed:**
- All cPanel plugin registration attempts
- Old installation scripts
- Experimental configuration files
- Diagnostic tools
- Outdated documentation

**Kept:**
- Essential plugin files
- WHM-specific configuration
- Current documentation
- Working installation scripts

The project is now focused solely on the **WHM plugin implementation** with a clean, professional structure.