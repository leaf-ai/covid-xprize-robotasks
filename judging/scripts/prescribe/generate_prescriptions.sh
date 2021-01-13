#!/usr/bin/env bash
# Copyright 2020 (c) Cognizant Digital Business, Evolutionary AI. All rights reserved. Issued under the Apache 2.0 License.

# This is a wrapper script for inference (generating predictions). Ultimately it runs the local predict.py module
# which is expected to exist. See prediction_module below.

# It is expected that cron will run this script on a schedule.
# See generate_predictions_local.py for more information
#
# This script assumes the repository has been downloaded locally.
# The predict.py API script is then run.

# See https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html for what these do
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o xtrace

echo "Running main script..."

repo_dir="$1"

# Locations of tasks and predict.py module
prescriptions_file="$repo_dir/tasks/prescribe_tasks.csv"
generate_prescriptions_wrapper="$repo_dir/judging/scripts/prescribe/generate_prescriptions.py"
prescription_module="$HOME/work/prescribe.py"
validation_module="$repo_dir/judging/scripts/prescribe/dummy_prescriptor_validation.py"

# Run script
pwd
command -v python
command -v pip
python --version
pip --version
python "$generate_prescriptions_wrapper" \
  --requested-predictions-file "$prescriptions_file" \
  --prescription-module "$prescription_module" \
  --validation-module "$validation_module"
