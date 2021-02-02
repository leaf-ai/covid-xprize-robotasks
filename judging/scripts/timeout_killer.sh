#!/usr/bin/env bash

# Copyright 2021 (c) Cognizant Digital Business, Evolutionary AI. All rights reserved. Issued under the Apache 2.0 License.

# Enforces the timeout for generating prescriptions.
# After the designated amount of time has elapsed, kills the process with the PID provided in $1 and any
# child processes thereof.
#
# The killing is done abruptly with SIGKILL so the output from the terminated process will be in an indeterminate
# state.
#
# Information about the kill is written to stdout

# See https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html for what these do
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
set -o xtrace

pid=$1

# Allow this amount of time before killing the job
KILL_AFTER=5s

# Wait until designated time has elapsed
sleep $KILL_AFTER

# If it's still running, kill it
if ps -p $pid > /dev/null
then
   echo "$(date) Timeout ($KILL_AFTER) has elapsed and job is still running. Killing PID $pid" >&2
   # enable the built-in version so we can use the "negative pid to kill children" trick
   enable kill
   kill -KILL -$pid
fi


