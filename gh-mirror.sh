#!/bin/bash

# GitHub Auto Mirror Script
# This script clones a repository, sets up mirroring to your own GitHub account,
# and configures the upstream branch properly.

set -e # Exit on any error

# Load environment variables
if [ -f ".env" ]; then
    source .env
fi

# Default values
MIRROR_DIR="${MIRROR_DIR:-$HOME/gh-mirrors}"
GITHUB_USERNAME="${GITHUB_USERNAME:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

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

# Function to show usage
show_usage() {
    echo "Usage: $0 <source_repo_url> [target_repo_name]"
    echo ""
    echo "Arguments:"
    echo "  source_repo_url    The URL of the repository to mirror (required)"
    echo "  target_repo_name   The name for the new repository (optional, defaults to original name)"
    echo ""
    echo "Environment variables (set in .env file or export):"
    echo "  MIRROR_DIR         Directory to store mirrored repos (default: ~/gh-mirrors)"
    echo "  GITHUB_USERNAME    Your GitHub username"
    echo "  GITHUB_TOKEN       Your GitHub personal access token"
    echo ""
    echo "Example:"
    echo "  $0 https://github.com/username/repo"
    echo "  $0 https://github.com/username/repo my-fork"
}

# Function to validate GitHub credentials
validate_github_creds() {
    if [ -z "$GITHUB_USERNAME" ]; then
        print_error "GITHUB_USERNAME is not set. Please set it in .env file or export it."
        exit 1
    fi

    if [ -z "$GITHUB_TOKEN" ]; then
        print_error "GITHUB_TOKEN is not set. Please set it in .env file or export it."
        exit 1
    fi
}

# Function to check if repository belongs to the user
check_repo_ownership() {
    local source_url="$1"

    echo $source_url

    # Extract owner and repo name from GitHub URL
    if [[ "$source_url" =~ https://github\.com/([^/]+)/([^/]+) ]]; then
        local owner="${BASH_REMATCH[1]}"
        local repo_name="${BASH_REMATCH[2]}"

        # Remove .git suffix if present
        repo_name="${repo_name%.git}"

        if [ "$owner" = "$GITHUB_USERNAME" ]; then
            print_error "Cannot mirror your own repository: $source_url"
            print_error "The source repository already belongs to you ($GITHUB_USERNAME)"
            exit 1
        fi
    else
        print_warning "Could not parse GitHub URL format. Proceeding with caution..."
    fi
}

# Function to extract repo name from URL
extract_repo_name() {
    local url="$1"
    local repo_name=$(basename "$url" .git)
    echo "$repo_name"
}

# Function to create GitHub repository
create_github_repo() {
    local repo_name="$1"
    local description="$2"

    print_status "Creating GitHub repository: $repo_name"

    # Check if repo already exists
    if curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$GITHUB_USERNAME/$repo_name" | grep -q '"id"'; then
        print_error "Repository $repo_name already exists on your GitHub account, please specify a different name"
        exit 1
    fi

    # Create the repository
    local response=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/user/repos" \
        -d "{
            \"name\": \"$repo_name\",
            \"description\": \"$description\",
            \"private\": false,
            \"auto_init\": false
        }")

    if echo "$response" | grep -q '"id"'; then
        print_success "GitHub repository created successfully"
    else
        print_error "Failed to create GitHub repository: $response"
        exit 1
    fi
}

# Function to setup repository mirroring
setup_mirror() {
    local source_url="$1"
    local repo_name="$2"
    local repo_path="$MIRROR_DIR/$repo_name"

    print_status "Setting up mirror for: $source_url"

    # Create mirror directory if it doesn't exist
    mkdir -p "$MIRROR_DIR"

    # Clone the repository if it doesn't exist, or update if it does
    if [ ! -d "$repo_path" ]; then
        print_status "Cloning repository..."
        git clone --mirror "$source_url" "$repo_path"
    else
        print_warning "Repository already exists at $repo_path. Attempting to update..."
        cd "$repo_path"
        git fetch --all
        cd - >/dev/null
    fi

    # Change to repository directory
    cd "$repo_path"

    # Add new origin (your GitHub repository)
    print_status "Setting new origin remote..."
    git remote set-url origin "https://github.com/$GITHUB_USERNAME/$repo_name.git"

    # Add upstream remote (the original repository)
    if git remote get-url upstream >/dev/null 2>&1; then
        git remote set-url upstream "$source_url"
    else
        git remote add upstream "$source_url"
    fi

    # Configure push to be disabled for upstream
    print_status "Configuring push settings..."
    git config remote.upstream.pushurl "no_push"

    # Remove problematic refs before pushing
    print_status "Cleaning up problematic references..."
    git for-each-ref --format='%(refname)' refs/ | grep -E '^refs/pull/' | while read ref; do
        git update-ref -d "$ref" 2>/dev/null || true
    done

    # Push to your GitHub repository
    print_status "Pushing to your GitHub repository..."

    # Push all branches and tags (mirror repositories handle this properly)
    git push origin --mirror

    print_success "Mirror pushed to your GitHub repository!"
    print_status "Repository location: $repo_path"
    print_status "Upstream: $source_url"
    print_status "Your mirror: https://github.com/$GITHUB_USERNAME/$repo_name"

    cd - >/dev/null
}

# Main script logic
main() {
    # Check if help is requested
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi

    # Check if source URL is provided
    if [ -z "$1" ]; then
        print_error "Source repository URL is required"
        show_usage
        exit 1
    fi

    local source_url="$1"
    local target_name="$2"

    # Validate GitHub credentials
    validate_github_creds

    # Check if repository belongs to the user
    check_repo_ownership "$source_url"

    # Extract repo name if not provided
    if [ -z "$target_name" ]; then
        target_name=$(extract_repo_name "$source_url")
    fi

    # Create description
    local description="Mirror of $source_url"

    print_status "Starting mirror process..."
    print_status "Source: $source_url"
    print_status "Target: $target_name"
    print_status "Mirror directory: $MIRROR_DIR"

    # Create GitHub repository
    create_github_repo "$target_name" "$description"

    # Setup mirror
    setup_mirror "$source_url" "$target_name"

    print_success "Mirror setup completed successfully!"
}

# Run main function with all arguments
main "$@"
