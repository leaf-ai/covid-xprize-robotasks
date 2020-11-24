FROM python:3.7-stretch

# install cron
RUN apt-get update -yqq && \
    apt-get -yqq --no-install-recommends --no-install-suggests install cron python3-pip

# Python requirements
COPY ./judging/requirements.txt $HOME/
RUN pip3 install -r requirements.txt

# add cron job
COPY ./judging/crontab /etc/cron.d/generate_predictions

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/generate_predictions

# Create the log file to be able to run tail
RUN touch /var/log/generate_predictions.log

# Copy dummy predict script to $HOME to simulate user sandbox layout
# Remove this for real sandbox -- user must supply predict.py
COPY ./judging/predict.py $HOME/work/predict.py

# Copy prediction generation scripts
RUN mkdir -p /usr/bin/judging $HOME/work
COPY ./judging/scripts/generate_predictions.sh /usr/bin/judging/
RUN chmod +x /usr/bin/judging/generate_predictions.sh

# Run the command on container startup
CMD cron && echo "Waiting for cron" && tail -f /var/log/generate_predictions.log