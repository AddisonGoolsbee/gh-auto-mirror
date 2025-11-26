#!/bin/bash

# GitHub Auto Mirror Utilities
# Shared functions for gh-mirror.sh and gh-mirror-update.sh

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

# Function to load environment variables
load_env() {
    # Prefer config dir next to installed scripts; fall back to script dir, then CWD
    local utils_dir
    utils_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local base_dir
    base_dir="$(dirname "$utils_dir")"
    local config_dir="${GH_MIRROR_CONFIG_DIR:-$HOME/.config/gh-auto-mirror}"

    local env_candidates=(
        "$config_dir/.env"
        "$base_dir/.env"
        ".env"
    )

    for env_file in "${env_candidates[@]}"; do
        if [ -f "$env_file" ]; then
            # shellcheck source=/dev/null
            source "$env_file"
            return
        fi
    done
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
        print_warning "Repository $repo_name already exists on your GitHub account, continuing..."
        local response='{"id":"already_exists"}'
    else
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
    fi

    if echo "$response" | grep -q '"id"'; then
        if echo "$response" | grep -q '"already_exists"'; then
            print_warning "GitHub repository creation skipped"
        else
            print_success "GitHub repository created successfully"
        fi
    else
        print_error "Failed to create GitHub repository: $response"
        exit 1
    fi
}

# Function to add mirror notice to README files
add_mirror_notice() {
    local repo_name="$1"
    local upstream_url=""

    # Get upstream URL
    if git remote get-url upstream >/dev/null 2>&1; then
        upstream_url=$(git remote get-url upstream)
    else
        print_warning "No upstream remote found for $repo_name"
        return 1
    fi

    # Create temporary working directory for bare repository
    local temp_work_dir=$(mktemp -d)
    print_status "Creating temporary working directory for file operations..."

    # Checkout the repository to temporary directory
    git --work-tree="$temp_work_dir" --git-dir="." checkout HEAD -- .

    # Find README files (case insensitive)
    local readme_files=()
    for readme in README.md README.rst README.txt README; do
        if [ -f "$temp_work_dir/$readme" ]; then
            readme_files+=("$readme")
        fi
    done

    # If no README found, create one
    if [ ${#readme_files[@]} -eq 0 ]; then
        print_status "No README found, creating README.md..."
        readme_files=("README.md")
    fi

    # Process each README file
    for readme in "${readme_files[@]}"; do
        local temp_file=$(mktemp)
        local mirror_notice="*This is a mirror. See upstream: $upstream_url*\n\n"

        # Check if mirror notice already exists
        if grep -q "This is a mirror. See upstream:" "$temp_work_dir/$readme" 2>/dev/null; then
            print_status "Mirror notice already exists in $readme, skipping..."
            continue
        fi

        # Add mirror notice at the beginning of the file
        echo -e "$mirror_notice$(cat "$temp_work_dir/$readme")" >"$temp_file"
        mv "$temp_file" "$temp_work_dir/$readme"

        print_status "Added mirror notice to $readme"
    done

    # Add and commit the changes using the bare repository
    if ! git --work-tree="$temp_work_dir" --git-dir="." diff --quiet; then
        git --work-tree="$temp_work_dir" --git-dir="." add .
        git --work-tree="$temp_work_dir" --git-dir="." commit -m "Add readme mirror line" >/dev/null 2>&1
        print_status "Committed mirror notice changes"
    fi

    # Clean up temporary directory
    rm -rf "$temp_work_dir"
}

# Function to clean up problematic references
cleanup_problematic_refs() {
    print_status "Cleaning up problematic references..."
    git for-each-ref --format='%(refname)' refs/ | grep -E '^refs/pull/' | while read ref; do
        git update-ref -d "$ref" 2>/dev/null || true
    done
}
