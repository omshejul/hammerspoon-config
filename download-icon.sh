#!/bin/bash

# Helper script to download icons from popular icon libraries
# Usage: ./download-icon.sh <library> <icon-name> [style]
# Examples:
#   ./download-icon.sh heroicons document-text outline
#   ./download-icon.sh lucide file-text
#   ./download-icon.sh simple-icons google

LIBRARY=$1
ICON_NAME=$2
STYLE=$3

ICONS_DIR="$HOME/.hammerspoon/icons"
mkdir -p "$ICONS_DIR"

case $LIBRARY in
    heroicons)
        STYLE=${STYLE:-outline}
        mkdir -p "$ICONS_DIR/heroicons/$STYLE"
        URL="https://raw.githubusercontent.com/tailwindlabs/heroicons/master/src/24/$STYLE/$ICON_NAME.svg"
        echo "Downloading Heroicon: $ICON_NAME ($STYLE style)..."
        curl -s "$URL" -o "$ICONS_DIR/heroicons/$STYLE/$ICON_NAME.svg"
        if [ $? -eq 0 ]; then
            echo "✓ Saved to: $ICONS_DIR/heroicons/$STYLE/$ICON_NAME.svg"
        else
            echo "✗ Failed to download. Check icon name and try again."
            echo "Browse icons at: https://heroicons.com/"
        fi
        ;;
    lucide)
        mkdir -p "$ICONS_DIR/lucide"
        URL="https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/$ICON_NAME.svg"
        echo "Downloading Lucide icon: $ICON_NAME..."
        curl -s "$URL" -o "$ICONS_DIR/lucide/$ICON_NAME.svg"
        if [ $? -eq 0 ]; then
            echo "✓ Saved to: $ICONS_DIR/lucide/$ICON_NAME.svg"
        else
            echo "✗ Failed to download. Check icon name and try again."
            echo "Browse icons at: https://lucide.dev/icons/"
        fi
        ;;
    simple-icons)
        mkdir -p "$ICONS_DIR/simple-icons"
        # Simple Icons uses different naming (kebab-case, lowercase)
        ICON_NAME_LOWER=$(echo "$ICON_NAME" | tr '[:upper:]' '[:lower:]' | tr '_' '-')
        URL="https://raw.githubusercontent.com/simple-icons/simple-icons/develop/icons/$ICON_NAME_LOWER.svg"
        echo "Downloading Simple Icon: $ICON_NAME..."
        curl -s "$URL" -o "$ICONS_DIR/simple-icons/$ICON_NAME.svg"
        if [ $? -eq 0 ]; then
            echo "✓ Saved to: $ICONS_DIR/simple-icons/$ICON_NAME.svg"
        else
            echo "✗ Failed to download. Check icon name and try again."
            echo "Browse icons at: https://simpleicons.org/"
        fi
        ;;
    *)
        echo "Unknown library: $LIBRARY"
        echo ""
        echo "Supported libraries:"
        echo "  heroicons    - https://heroicons.com/"
        echo "  lucide       - https://lucide.dev/"
        echo "  simple-icons - https://simpleicons.org/"
        echo ""
        echo "Usage: $0 <library> <icon-name> [style]"
        echo "Examples:"
        echo "  $0 heroicons document-text outline"
        echo "  $0 lucide file-text"
        echo "  $0 simple-icons google"
        exit 1
        ;;
esac

