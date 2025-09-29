#!/bin/bash

# Create a 48x48 PNG icon for the WHM plugin
# This script creates a simple but professional icon

echo "Creating 48x48 PNG icon for WHM plugin..."

# For systems with ImageMagick
if command -v convert >/dev/null 2>&1; then
    echo "Using ImageMagick to convert SVG to PNG..."
    convert -background transparent -size 48x48 icon.svg wp_temp_accounts_icon.png
    echo "✅ Icon created: wp_temp_accounts_icon.png"
    exit 0
fi

# For systems with inkscape
if command -v inkscape >/dev/null 2>&1; then
    echo "Using Inkscape to convert SVG to PNG..."
    inkscape --export-png=wp_temp_accounts_icon.png --export-width=48 --export-height=48 icon.svg
    echo "✅ Icon created: wp_temp_accounts_icon.png"
    exit 0
fi

# Fallback: Create a simple text-based approach
echo "Neither ImageMagick nor Inkscape found."
echo "Creating a simple icon placeholder..."

# Create a simple HTML/CSS based icon that can be manually converted
cat > icon_template.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
<style>
.icon {
    width: 48px;
    height: 48px;
    background: linear-gradient(135deg, #21759B 0%, #464646 100%);
    border-radius: 50%;
    position: relative;
    font-family: Arial, sans-serif;
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    font-size: 20px;
    font-weight: bold;
    text-shadow: 0 1px 2px rgba(0,0,0,0.5);
    border: 2px solid #1e293b;
    box-shadow: 0 2px 8px rgba(0,0,0,0.3);
}
.icon::after {
    content: "⏱";
    position: absolute;
    top: -2px;
    right: -2px;
    width: 12px;
    height: 12px;
    background: linear-gradient(135deg, #FFA500 0%, #FF6B00 100%);
    border-radius: 50%;
    font-size: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    border: 1px solid white;
}
</style>
</head>
<body style="margin: 0; padding: 20px; background: white;">
<div class="icon">W</div>
<p>To create the PNG icon:</p>
<ol>
<li>Open this file in a browser</li>
<li>Take a screenshot of the icon</li>
<li>Crop to 48x48 pixels</li>
<li>Save as wp_temp_accounts_icon.png</li>
</ol>
</body>
</html>
EOF

echo "✅ Created icon template: icon_template.html"
echo ""
echo "To create the 48x48 PNG icon:"
echo "1. Open icon_template.html in a web browser"
echo "2. Take a screenshot of the icon"
echo "3. Crop to exactly 48x48 pixels"
echo "4. Save as wp_temp_accounts_icon.png"
echo ""
echo "Or install ImageMagick:"
echo "  yum install ImageMagick"
echo "  dnf install ImageMagick"
echo "  apt-get install imagemagick"
echo ""