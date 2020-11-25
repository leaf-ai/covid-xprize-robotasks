FROM python:3.7-stretch

ENV HOME_DIR=/home/xprize

# Create an xprize user
RUN useradd -ms /bin/bash -d ${HOME_DIR} -u 1000 xprize \
    && echo xprize:pw | chpasswd

WORKDIR $HOME_DIR

# install cron
RUN apt-get update -yqq && \
    apt-get -yqq --no-install-recommends --no-install-suggests install cron python3-pip

# add cron job
COPY ./judging/crontab /etc/cron.d/generate_predictions

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/generate_predictions

# Create the log file to be able to run tail
RUN touch /var/log/generate_predictions.log

# /tasks is mounted at run time
CMD $HOME_DIR/tasks/entrypoint.sh
