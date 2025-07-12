#!/bin/bash

# GitHub Auto Mirror Script
# This script clones a repository, sets up mirroring to your own GitHub account,
# and configures the upstream branch properly.

set -e # Exit on any error

# Load shared utilities
source "$(dirname "$0")/utils/gh-mirror-utils.sh"

# Load environment variables
load_env

# Default values
MIRROR_DIR="${MIRROR_DIR:-$HOME/gh-mirrors}"
GITHUB_USERNAME="${GITHUB_USERNAME:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

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

    # Add mirror notice to README files
    print_status "Adding mirror notice to README files..."
    add_mirror_notice "$repo_name"

    # Remove problematic refs before pushing
    cleanup_problematic_refs

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
