#!/usr/bin/env bash

# Landing pad for the schedule job. Does nothing but launch bootstrap for predictions or prescriptions
# *and capture logging*
# This file needs to be deployed *manually* to the sandboxes. It is expected to be launched by a cron job

# See https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html for what these do
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o xtrace

# What mode is this sandbox running in? "prescriptions" or "predictions"
mode="prescriptions"

# Create logs dir if necessary
logs_dir=$HOME/work/$mode/logs
mkdir -p "$logs_dir"

# Set up log file path
log_file_name=predict_$(date +"%Y_%m_%d_%H%M").txt
log_file_path=$logs_dir/$log_file_name

# Launch bootstrap
echo "Running $mode generator bootstrap..." &>> "$log_file_path"
"$HOME"/work/bootstrap.sh $mode &>> "$log_file_path"