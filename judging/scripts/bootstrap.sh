#!/usr/bin/env bash

# As its name suggests, this is a bootstrap script. It is intended to be called by cron. Its sole purpose is to download
# the latest "tasks" git repository, then hand control over to generate_predictions.sh to generate the predictions.
# This is split into a separate script to give us flexibility in updating the main generate_predictions.sh script.

# See https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html for what these do
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o xtrace

echo "Running bootstrap..."

# Get latest from github as a zip file and extract it to user home directory
repo_name="covid-xprize-robotasks"
# todo: change to "main" once everything merged
branch="cron-solution"
repo_dir="$HOME/repo/$repo_name-$branch"
curl --silent --location --output "$HOME/$repo_name.zip" https://github.com/leaf-ai/$repo_name/archive/$branch.tar.gz
mkdir -p "$HOME/repo" && tar --overwrite --extract --directory "$HOME/repo/" --file $repo_name.zip

# Launch the main script
main_script="$repo_dir"/judging/scripts/generate_predictions.sh
chmod +x "$main_script"
$main_script "$repo_dir"