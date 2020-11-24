#!/usr/bin/env bash

#
# Creates the cron job to run the local prediction generation
# ***WARNING*** Destructive! Overwrites current user crontab
#

# See https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html for what these do
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o xtrace

crontab - <<EOF
0 7 * * * /usr/bin/flock -w 0 /tmp/generate_predictions.lock cd $HOME && ./judging/scripts/generate_predictions.sh <path to github mount> <path to predictions module> > /tmp/generate_predictions_\$\$.log 2>&1
EOF