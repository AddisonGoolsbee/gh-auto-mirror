# GitHub Auto Mirror

Have you ever started a project with someone else, only to be dismayed by the fact that THEY MADE THE REPOSITORY FIRST I'LL KILL YOU GRAAHHHHH!

Worry no more, I've made a set of scripts to mirror GitHub repositories to your own GitHub account and to sync your mirrors.

## Installation

Make a `.env` file based off of the `.env.example`
Run `bash install.sh`

## Usage

### gh-mirror-create

Mirrors a github repository given its url and an optional new name

Example: `gh-mirror-create https://github.com/AddisonGoolsbee/gnome-torture gnome` will download the repository, rename it to 'gnome', copy the git structure (so it's not marked as a fork), add a line to the top of the readme explaining this repo is a mirror, and then use the GitHub API to create a new repository under your account

### gh-mirror-sync

Re-mirrors each repository in your mirrors folder to keep them up-to-date. Takes no arguments, just run `gh-mirror-sync`

### Automating Sync

It's annoying to have to remember to run gh-mirror-sync every once in a while. The way to automate this is very machine dependent, but here is the macOS LaunchAgent setup that ships with the repo.

1. Edit the copied file so every path is absolute and matches your setup:
   - `ProgramArguments[0]` must point to the actual `gh-mirror-sync` script or wrapper, e.g. `/Users/<you>/.local/bin/gh-mirror-sync`.
   - Update `StandardOutPath`/`StandardErrorPath` to a writable log location, e.g. `/Users/<you>/Library/Logs/gh-mirror-sync.log` (create the folder first).
   - If your script needs a specific working directory, add a `WorkingDirectory` key that also uses an absolute path.
2. Copy the sample plist somewhere sensible (you might need to create the folder first):
   ```bash
   cp example.plist ~/Library/LaunchAgents/com.addisongoolsbee.gh-mirror-sync.plist
   ```
3. Adjust how often it runs. The example uses `StartCalendarInterval` (daily at 18:00). You can swap it for `StartInterval` with a value like `21600` (6 hours) or tweak the calendar keys—just keep it valid plist XML.
4. Load, inspect, and optionally force-run the agent:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.addisongoolsbee.gh-mirror-sync.plist
   launchctl list | grep -i gh-mirror
   launchctl start com.addisongoolsbee.gh-mirror-sync
   ```
5. Confirm it's working by watching the log you configured:
   ```bash
   tail -f /Users/<you>/Library/Logs/gh-mirror-sync.log
   ```
   You should see each run print the same output you'd expect from running `gh-mirror-sync` manually.
