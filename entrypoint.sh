#!/bin/bash

# Start the run once job.
echo "Docker container has been started"

declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /home/xprize/container.env

# Setup a cron schedule
echo "SHELL=/bin/bash
BASH_ENV=/home/xprize/container.env
* * * * * /work/hello.sh >> /var/log/cron.log 2>&1
# This extra line makes it a valid cron" > scheduler.txt

crontab -u xprize scheduler.txt
cron -f
