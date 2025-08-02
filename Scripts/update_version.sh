#!/bin/bash

# Build Script für automatische Versionsnummer-Aktualisierung
# Format: 1.YYYY.MM.DD

# Aktuelles Datum im gewünschten Format
DATE=$(date +"%Y.%m.%d")
VERSION="1.$DATE"

# Build-Nummer (kann inkrementiert werden)
BUILD_NUMBER=$(date +"%Y%m%d%H%M")

echo "🔢 Updating version to: $VERSION"
echo "🏗️ Build number: $BUILD_NUMBER"

# Info.plist Pfad (anpassen falls nötig)
INFO_PLIST="$PROJECT_DIR/$INFOPLIST_FILE"

if [ -f "$INFO_PLIST" ]; then
    # Version aktualisieren
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$INFO_PLIST"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$INFO_PLIST"
    
    # Build-Datum hinzufügen (für Debug-Info)
    BUILD_DATE=$(date "+%Y-%m-%d %H:%M:%S")
    /usr/libexec/PlistBuddy -c "Set :BuildDate $BUILD_DATE" "$INFO_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :BuildDate string $BUILD_DATE" "$INFO_PLIST"
    
    echo "✅ Version updated successfully"
    echo "   Version: $VERSION"
    echo "   Build: $BUILD_NUMBER"
    echo "   Date: $BUILD_DATE"
else
    echo "❌ Info.plist not found at: $INFO_PLIST"
fi