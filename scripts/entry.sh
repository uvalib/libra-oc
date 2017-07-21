#!/usr/bin/env bash

# remove stale pid files
rm -f $APP_HOME/tmp/pids/server.pid > /dev/null 2>&1

# run the sitemap generator process
nohup scripts/sitemap_generator.sh &

# run the server
rails server -b 0.0.0.0 -p 3000 Puma
