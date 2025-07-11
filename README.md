# GitHub Auto Mirror

A bash script that automatically mirrors any Git repository to your own GitHub account, setting up proper upstream tracking and preventing accidental pushes to the original repository.

## Features

- 🔄 **Automatic Mirroring**: Clone any repository and mirror it to your GitHub account
- 🔒 **Safe Configuration**: Prevents accidental pushes to the original repository
- 📁 **Organized Storage**: Stores mirrored repos in a configurable directory
- 🎨 **Colored Output**: Clear, colored status messages for better UX
- ⚙️ **Environment Configuration**: Easy setup via environment variables
- 🔄 **Update Support**: Can update existing mirrors with latest changes

## Prerequisites

- Git installed on your system
- A GitHub account
- A GitHub Personal Access Token with `repo` and `workflow` scopes

## Setup

1. **Clone or download this repository**

2. **Make the script executable**:
   ```bash
   chmod +x gh-mirror.sh
   ```

3. **Configure your environment**:
   ```bash
   cp env.example .env
   ```

4. **Edit the `.env` file** with your GitHub credentials:
   ```bash
   # Directory where mirrored repositories will be stored
   MIRROR_DIR="$HOME/gh-mirrors"
   
   # Your GitHub username
   GITHUB_USERNAME="your-github-username"
   
   # Your GitHub personal access token
   GITHUB_TOKEN="your-github-personal-access-token"
   ```

## Getting a GitHub Personal Access Token

1. Go to [GitHub Settings > Tokens](https://github.com/settings/tokens)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "GitHub Auto Mirror")
4. Select the following scopes:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
5. Click "Generate token"
6. Copy the token and paste it in your `.env` file

## Usage

### Basic Usage

Mirror a repository using its original name:
```bash
./gh-mirror.sh https://github.com/username/repo.git
```

### Custom Repository Name

Mirror a repository with a custom name:
```bash
./gh-mirror.sh https://github.com/username/repo.git my-custom-name
```

### Help

Show usage information:
```bash
./gh-mirror.sh --help
```

## What the Script Does

1. **Validates Configuration**: Checks that your GitHub credentials are set
2. **Creates GitHub Repository**: Creates a new repository on your GitHub account
3. **Clones Source Repository**: Downloads the repository to your local mirror directory
4. **Configures Remotes**:
   - Sets `origin` to your GitHub repository
   - Sets `upstream` to the original repository
   - Disables pushing to upstream to prevent accidents
5. **Pushes to Your Repository**: Mirrors all branches and tags to your GitHub account

## Repository Structure After Mirroring

```
~/gh-mirrors/
├── repo-name/
│   ├── .git/
│   └── [repository contents]
└── another-repo/
    ├── .git/
    └── [repository contents]
```

## Remote Configuration

After running the script, your repository will have the following remote configuration:

- **origin**: `https://github.com/YOUR_USERNAME/repo-name.git` (your mirror)
- **upstream**: `https://github.com/original-owner/repo-name.git` (original repo)

## Updating Mirrors

To update an existing mirror with the latest changes from the original repository:

```bash
cd ~/gh-mirrors/repo-name
git fetch upstream
git push origin --mirror
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MIRROR_DIR` | Directory to store mirrored repositories | `~/gh-mirrors` |
| `GITHUB_USERNAME` | Your GitHub username | Required |
| `GITHUB_TOKEN` | Your GitHub personal access token | Required |

## Security Notes

- Keep your `.env` file secure and never commit it to version control
- The script uses HTTPS for all Git operations
- Your GitHub token is only used for API calls and is not stored in the repository
- The script prevents accidental pushes to the original repository

## Troubleshooting

### "Repository already exists" Warning
This is normal if you've already mirrored the repository before. The script will update the existing mirror.

### "Permission denied" Error
Make sure the script is executable:
```bash
chmod +x gh-mirror.sh
```

### "GitHub credentials not set" Error
Check that your `.env` file exists and contains valid `GITHUB_USERNAME` and `GITHUB_TOKEN` values.

### "Failed to create GitHub repository" Error
- Verify your GitHub token has the correct permissions
- Check that the repository name doesn't conflict with an existing repository
- Ensure your GitHub account can create repositories

## License

This script is provided as-is for educational and personal use.

## Contributing

Feel free to submit issues or pull requests to improve the script!source