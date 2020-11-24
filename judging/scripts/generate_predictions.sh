#!/usr/bin/env bash

# This is a wrapper script for inference (generating predictions). Ultimately it runs the local predict.py module
# which is expected to exist. See prediction_module below.

# It is expected that cron will run this script on a schedule.
# See generate_predictions_local.py for more information
#
# The latest script is pulled from github, along with the latest tasks list containing predictions to be generated
# The script is then run.

# See https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html for what these do
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o xtrace

# Get latest from github as a zip file and extract it to user home directory
repo_name="covid-xprize-robotasks"
# todo: change to "main" once everything merged
branch="cron-solution"
repo_dir="$HOME/repo/$repo_name-$branch"
curl --silent --location --output "$HOME/$repo_name.zip" https://github.com/leaf-ai/$repo_name/archive/$branch.tar.gz
mkdir "$HOME/repo" && tar --overwrite --extract --directory "$HOME/repo/" --file $repo_name.zip

# Locations of tasks and predict.py module
predictions_file="$repo_dir/tasks/tasks.csv"
generate_predictions_wrapper="$repo_dir/judging/generate_predictions_local.py"
prediction_module="$HOME/work/predict.py"

# Run script
# Need to set up these env vars as cron has a restricted PATH by default
export PATH=/usr/local/bin/:$PATH
export PYTHONPATH=/usr/local/lib/python3.7/site-packages
which python
which pip
python --version
pip --version
pip show pandas
python "$generate_predictions_wrapper" \
  --requested-predictions-file "$predictions_file" \
  --prediction-module "$prediction_module"