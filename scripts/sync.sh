#!/bin/bash
set -e

CONFIG_DIR="/app/config"
TMP_CLONE="/tmp/asf-config"
REPOSITORY_URL="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY_USERNAME}/${GITHUB_REPOSITORY_NAME}.git"
BRANCH="master"

mkdir -p "$CONFIG_DIR"
mkdir -p "$TMP_CLONE"

git config --global --add safe.directory "$CONFIG_DIR"

echo "Starting ArchiSteamFarm"

cd /asf
dotnet ArchiSteamFarm.dll --no-restart --service &

ASF_PID=$!

echo "Syncing configs in background"

(
if [ -d "$CONFIG_DIR/.git" ]; then
    echo "Updating existing configs"

    cd "$CONFIG_DIR"

    git config user.name "${GITHUB_USERNAME}"
    git config user.email "${GITHUB_EMAIL}"
    git reset --hard
    git pull origin "$BRANCH"
else
    echo "Cloning configs from private repository to temp folder"

    rm -rf "$TMP_CLONE"

    git clone "$REPOSITORY_URL" "$TMP_CLONE" || { echo "Git clone failed"; exit 1; }

    echo "Copying configs to $CONFIG_DIR, preserving .gitkeep"

    find "$CONFIG_DIR" -mindepth 1 ! -name '.gitkeep' -exec rm -rf {} + || true
    cp -r "$TMP_CLONE"/* "$CONFIG_DIR"/
    cp -r "$TMP_CLONE"/.* "$CONFIG_DIR"/ 2>/dev/null || true

    cd "$CONFIG_DIR"

    git config user.name "${GITHUB_USERNAME}"
    git config user.email "${GITHUB_EMAIL}"
fi

echo "Monitoring $CONFIG_DIR for changes"

while inotifywait -r -e modify,create,delete,move "$CONFIG_DIR"; do
    sleep 0.5

    cd "$CONFIG_DIR"

    git config user.name "${GITHUB_USERNAME}"
    git config user.email "${GITHUB_EMAIL}"

    if [ -n "$(git status --porcelain)" ]; then
        git add -A || true
        git commit -a -m "$(git status --porcelain | wc -l) files | $(git status --porcelain | sed '{:q;N;s/\n/, /g;t q}' | sed 's/^ *//g')" || true
        git push "$REPOSITORY_URL" "$BRANCH"

        echo "Config changes pushed to GitHub /${GITHUB_REPOSITORY_USERNAME}/${GITHUB_REPOSITORY_NAME}"
    fi
done
) &

wait $ASF_PID
