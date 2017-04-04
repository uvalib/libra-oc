# remove stale pid files
rm -f $APP_HOME/tmp/pids/server.pid > /dev/null 2>&1

# run the statistics rollup process
nohup scripts/stats_rollup.sh &

# run the server
rails server -b 0.0.0.0 -p 3000 Puma
