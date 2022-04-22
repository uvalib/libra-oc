#!/usr/bin/env bash

# run the virus checker signature refresher
scripts/update_viruscheck_signatures.sh &

# start the sidekiq pool daemon
scripts/start_workers.sh
