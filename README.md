# GitHub Auto Mirror

A set of scripts to automatically mirror GitHub repositories to your own GitHub account.

## Scripts

### `gh-mirror.sh`

Creates a new mirror of a GitHub repository.

**Usage:**

```bash
./gh-mirror.sh <source_repo_url> [target_repo_name]
```

**Example:**

```bash
./gh-mirror.sh https://github.com/username/repo
./gh-mirror.sh https://github.com/username/repo my-fork
```

### `gh-mirror-update.sh`

Updates all existing mirrors by pulling latest changes and pushing them to your GitHub repositories.

**Usage:**

```bash
./gh-mirror-update.sh
```

## Setup

1. Create a `.env` file with your GitHub credentials:

```bash
GITHUB_USERNAME=your_username
GITHUB_TOKEN=your_personal_access_token
MIRROR_DIR=/path/to/your/mirrors
```

2. Make scripts executable:

```bash
chmod +x gh-mirror.sh gh-mirror-update.sh
```

## Automatic Updates

To set up automatic updates every 12 hours, add this to your crontab:

```bash
# Edit crontab
crontab -e

# Add this line (runs every 12 hours at 2 AM and 2 PM)
0 2,14 * * * /path/to/gh-auto-mirror/gh-mirror-update.sh >> /path/to/gh-auto-mirror/update.log 2>&1
```

**Alternative schedules:**

- Every 6 hours: `0 */6 * * *`
- Every day at 3 AM: `0 3 * * *`
- Every hour: `0 * * * *`

## Features

- ✅ Creates bare mirror repositories
- ✅ Automatically excludes problematic GitHub refs (pull requests)
- ✅ Configures upstream remotes for easy updates
- ✅ Handles existing repositories gracefully
- ✅ Colored output for better readability
- ✅ Comprehensive error handling
- ✅ Automatic cleanup of problematic references
- ✅ Batch update all mirrors
- ✅ Rate limiting between operations

## Requirements

- Git
- curl
- bash
- GitHub Personal Access Token with repo permissions
