#
# Runner process to generate the sitemap on a nightly basis
#

# source the helper...
DIR=$(dirname $0)
. $DIR/common.sh

# set the appropriate logger
export NAME=$(basename $0 .sh)
export LOGGER=$(logger_name "$NAME.log")

# the time we want the action to occur
export ACTION_TIME="00:30"

# helpful message...
logit "Sitemap generator starting up..."

# forever...
while true; do

   # sleeping message...
   logit "Sleeping until $ACTION_TIME..."
   sleep_until $ACTION_TIME

   # determine if we are the active host... only run on one host even though we may be deployed on many
   if is_active_host; then

      # starting message
      logit "Beginning SIS export sequence"

      if [ $ENABLE_TEST_FEATURES == 'n' ]; then
        bundle exec rake sitemap:refresh >> $LOGGER 2>&1
      else
        bundle exec rake sitemap:refresh:no_ping >> $LOGGER 2>&1
      fi
      res=$?

      # ending message
      logit "Sitemap generator completes with status: $res"

   else
      logit "Not the active host; doing nothing"
   fi

   # sleep for another minute
   sleep 60

done

# never get here...
exit 0

#
# end of file
#