#!/usr/bin/env bash

# See https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html for what these do
#set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o xtrace

# Runs the Python script to generate predictions.
# It is expected that cron will run this script on a schedule.
# See generate_predictions_local.py for more information
#
# The latest script is pulled from github, along with the latest tasks list containing predictions to be generated
# The script is then run.

# Get latest from github as a zip file and extract it to user home directory
cd "$HOME" || exit 1
curl -sLo covid-xprize-robotasks.zip https://github.com/leaf-ai/covid-xprize-robotasks/archive/cron-solution.zip
unzip covid-xprize-robotasks.zip

# Locations of tasks and predict.py module
predictions_file="$HOME/covid-xprize-robotasks/judging/tasks.csv"
generate_predictions_wrapper="$HOME/covid-xprize-robotasks/judging/generate_predictions_local.py"
prediction_module="$HOME/work/predict.py"

# TODO: activate venv required?

which python3
which pip3
python3 --version
pip3 --version
pip3 show pandas

# Run script
# Need to set up these env vars as cron has a restricted PATH by default
export PATH=/usr/local/bin/:$PATH
export PYTHONPATH=/usr/local/lib/python3.7/site-packages
python "$generate_predictions_wrapper" \
  --requested-predictions-file "$predictions_file" \
  --prediction-module "$prediction_module"