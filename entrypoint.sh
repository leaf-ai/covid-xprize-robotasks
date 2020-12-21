#!/bin/bash

# Copyright 2020 (c) Cognizant Digital Business, Evolutionary AI. All rights reserved. Issued under the Apache 2.0 License.

# Start the run once job.
echo "Docker container has been started"

crontab -u xprize - <<EOF
* * * * * /home/xprize/work/hello.sh >> /tmp/cron.log 2>&1
EOF
