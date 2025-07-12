#!/bin/bash

# GitHub Mirror Update Script
# This script updates all mirrored repositories by pulling latest changes
# and pushing them to your GitHub repositories.

set -e # Exit on any error

# Load shared utilities
source "$(dirname "$0")/utils/gh-mirror-utils.sh"

# Load environment variables
load_env

# Default values
MIRROR_DIR="${MIRROR_DIR:-$HOME/gh-mirrors}"
GITHUB_USERNAME="${GITHUB_USERNAME:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# Function to update a single mirror repository
update_mirror() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")

    print_status "Updating mirror: $repo_name"

    # Change to repository directory
    cd "$repo_path"

    # Check if this is a valid git repository (handle both regular and bare repos)
    if [ ! -d ".git" ] && [ ! -f "HEAD" ] && [ ! -d "refs" ]; then
        print_warning "Skipping $repo_name - not a git repository"
        return 1
    fi

    # Check if upstream remote exists
    if ! git remote get-url upstream >/dev/null 2>&1; then
        print_warning "Skipping $repo_name - no upstream remote found"
        return 1
    fi

    # Fetch latest changes from upstream
    print_status "Fetching latest changes from upstream..."
    if ! git fetch upstream --prune; then
        print_error "Failed to fetch from upstream for $repo_name"
        return 1
    fi

    # Force reset to upstream to avoid merge conflicts
    print_status "Resetting to upstream changes..."
    # Get the default branch from upstream
    local default_branch=$(git ls-remote --symref upstream HEAD | grep 'ref: refs/heads/' | sed 's/.*refs\/heads\///' | sed 's/[[:space:]].*//')
    if [ -z "$default_branch" ]; then
        default_branch="main" # fallback to main
    fi
    print_status "Using default branch: $default_branch"
    # For bare repositories, we need to update the HEAD reference directly
    git update-ref HEAD "upstream/$default_branch"

    # Add mirror notice to README files
    print_status "Adding mirror notice to README files..."
    add_mirror_notice "$repo_name"

    # Remove problematic refs before pushing
    cleanup_problematic_refs

    # Push all changes to your GitHub repository
    print_status "Pushing updates to your GitHub repository..."
    if git push origin --mirror; then
        print_success "Successfully updated $repo_name"
    else
        print_error "Failed to push updates for $repo_name"
        return 1
    fi

    cd - >/dev/null
}

# Function to update all mirrors
update_all_mirrors() {
    print_status "Starting mirror update process..."
    print_status "Mirror directory: $MIRROR_DIR"

    # Check if mirror directory exists
    if [ ! -d "$MIRROR_DIR" ]; then
        print_error "Mirror directory does not exist: $MIRROR_DIR"
        exit 1
    fi

    # Count total repositories
    local total_repos=0
    local updated_repos=0
    local failed_repos=0

    # Process each repository in the mirror directory
    for repo_path in "$MIRROR_DIR"/*; do
        if [ -d "$repo_path" ]; then
            total_repos=$((total_repos + 1))

            if update_mirror "$repo_path"; then
                updated_repos=$((updated_repos + 1))
            else
                failed_repos=$((failed_repos + 1))
            fi

            # Add a small delay between repositories to be nice to GitHub's API
            sleep 1
        fi
    done

    # Print summary
    print_status "Update process completed!"
    print_status "Total repositories: $total_repos"
    print_success "Successfully updated: $updated_repos"
    if [ $failed_repos -gt 0 ]; then
        print_warning "Failed to update: $failed_repos"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -v, --verbose  Enable verbose output"
    echo ""
    echo "Environment variables (set in .env file or export):"
    echo "  MIRROR_DIR         Directory containing mirrored repos (default: ~/gh-mirrors)"
    echo "  GITHUB_USERNAME    Your GitHub username"
    echo "  GITHUB_TOKEN       Your GitHub personal access token"
    echo ""
    echo "This script updates all mirrored repositories by:"
    echo "  1. Fetching latest changes from upstream"
    echo "  2. Cleaning up problematic references"
    echo "  3. Pushing updates to your GitHub repositories"
}

# Main script logic
main() {
    # Check if help is requested
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
        exit 0
    fi

    # Validate GitHub credentials
    validate_github_creds

    # Update all mirrors
    update_all_mirrors
}

# Run main function with all arguments
main "$@"
