#!/usr/bin/env bash

# Runs the Python script to generate predictions.
# It is expected that cron will run this script on a schedule.
# See generate_predictions_local.py for more information
#
# The latest script is pulled from github, along with the latest tasks list containing predictions to be generated
# The script is then run.

# TODO: pull tasks list and generate_predictions_local.py script from github to local dir

# Retrieve command line params
predictions_file="$1"
prediction_module="$2"

# TODO: activate venv required?

# Run script
python ./judging/generate_predictions_local.py \
  --requested-predictions-file "$predictions_file" \
  --prediction-module "$prediction_module"