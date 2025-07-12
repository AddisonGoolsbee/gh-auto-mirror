#!/bin/bash

# GitHub Auto Mirror Installation Script
# This script installs the GitHub mirror scripts to ~/.local/bin

set -e # Exit on any error

echo "🚀 Installing GitHub Auto Mirror scripts..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
print_status "Script directory: $SCRIPT_DIR"

# Define the target directory
TARGET_DIR="$HOME/.local/bin"
print_status "Target directory: $TARGET_DIR"

# Create .local/bin directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    print_status "Creating directory: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    print_success "Created $TARGET_DIR"
else
    print_status "Directory already exists: $TARGET_DIR"
fi

# Check if scripts exist in the current directory
SCRIPTS=("gh-mirror-create.sh" "gh-mirror-sync.sh" "utils/gh-mirror-utils.sh")
MISSING_SCRIPTS=()

for script in "${SCRIPTS[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$script" ]; then
        MISSING_SCRIPTS+=("$script")
    fi
done

if [ ${#MISSING_SCRIPTS[@]} -gt 0 ]; then
    print_error "Missing scripts: ${MISSING_SCRIPTS[*]}"
    print_error "Please run this script from the directory containing the GitHub mirror scripts."
    exit 1
fi

# Create utils subdirectory
UTILS_DIR="$TARGET_DIR/utils"
if [ ! -d "$UTILS_DIR" ]; then
    print_status "Creating utils directory: $UTILS_DIR"
    mkdir -p "$UTILS_DIR"
    print_success "Created $UTILS_DIR"
else
    print_status "Utils directory already exists: $UTILS_DIR"
fi

# Check if environment file exists
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    print_warning ".env file not found. You'll need to create a .env file manually in $TARGET_DIR"
fi

# Copy scripts to .local/bin and rename them
print_status "Copying scripts to $TARGET_DIR..."

cp "$SCRIPT_DIR/gh-mirror-create.sh" "$TARGET_DIR/gh-mirror-create"
cp "$SCRIPT_DIR/gh-mirror-sync.sh" "$TARGET_DIR/gh-mirror-sync"
cp "$SCRIPT_DIR/utils/gh-mirror-utils.sh" "$UTILS_DIR/gh-mirror-utils.sh"

print_success "Scripts copied successfully"

# Copy environment file if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    print_status "Copying environment file..."
    if [ -f "$TARGET_DIR/.env" ]; then
        # Append with extra newline if target file already exists
        echo "" >>"$TARGET_DIR/.env"
        cat "$SCRIPT_DIR/.env" >>"$TARGET_DIR/.env"
        print_success "Environment file appended to existing .env"
    else
        # Copy if target file doesn't exist
        cp "$SCRIPT_DIR/.env" "$TARGET_DIR/.env"
        print_success "Environment file copied"
    fi
fi

# Make scripts executable
print_status "Making scripts executable..."
chmod +x "$TARGET_DIR/gh-mirror-create"
chmod +x "$TARGET_DIR/gh-mirror-sync"
chmod +x "$UTILS_DIR/gh-mirror-utils.sh"

print_success "Scripts are now executable"

# Check if .local/bin is already in PATH
if [[ ":$PATH:" == *":$TARGET_DIR:"* ]]; then
    print_status "$TARGET_DIR is already in your PATH"
else
    print_status "Adding $TARGET_DIR to your PATH..."

    # Detect shell and add to appropriate config file
    SHELL_CONFIG=""
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
        if [ ! -f "$SHELL_CONFIG" ]; then
            SHELL_CONFIG="$HOME/.bash_profile"
        fi
    else
        print_warning "Could not detect shell type. Please manually add $TARGET_DIR to your PATH"
        SHELL_CONFIG=""
    fi

    if [ -n "$SHELL_CONFIG" ]; then
        # Check if the PATH export is already in the config file
        if grep -q "$TARGET_DIR" "$SHELL_CONFIG" 2>/dev/null; then
            print_status "PATH export already exists in $SHELL_CONFIG"
        else
            echo "" >>"$SHELL_CONFIG"
            echo "# GitHub Auto Mirror scripts" >>"$SHELL_CONFIG"
            echo "export PATH=\"$TARGET_DIR:\$PATH\"" >>"$SHELL_CONFIG"
            print_success "Added PATH export to $SHELL_CONFIG"
        fi
    fi
fi

# Verify installation
print_status "Verifying installation..."
if [ -x "$TARGET_DIR/gh-mirror-create" ] && [ -x "$TARGET_DIR/gh-mirror-sync" ] && [ -x "$UTILS_DIR/gh-mirror-utils.sh" ]; then
    print_success "All scripts are installed and executable!"
else
    print_error "Installation verification failed"
    exit 1
fi

# Show environment setup instructions
echo ""
print_status "📝 Environment Setup Required:"
echo ""
echo "1. Copy the environment template:"
echo "   cp $TARGET_DIR/env.example $TARGET_DIR/.env"
echo ""
echo "2. Edit the .env file with your GitHub credentials:"
echo "   nano $TARGET_DIR/.env"
echo ""
echo "3. Required environment variables:"
echo "   • GITHUB_USERNAME - Your GitHub username"
echo "   • GITHUB_TOKEN - Your GitHub personal access token"
echo "   • MIRROR_DIR - Directory for mirrored repos (optional, defaults to ~/gh-mirrors)"
echo ""
echo "4. Generate a GitHub token at: https://github.com/settings/tokens"
echo "   Required scopes: repo, workflow"
echo ""
echo "Note: The .env file will be in $TARGET_DIR so the scripts can find it automatically."

echo ""
print_success "🎉 Installation complete!"
echo ""
echo "The scripts are installed in: $TARGET_DIR"
echo "This directory has been added to your PATH in: $SHELL_CONFIG"
echo ""
echo "You may need to reload your shell configuration:"
echo "  source $SHELL_CONFIG"
echo ""
echo "You can now use the following commands from anywhere:"
echo "  • gh-mirror-create  - Create a new mirror repository"
echo "  • gh-mirror-sync    - Sync an existing mirror repository"
