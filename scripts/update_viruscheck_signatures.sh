#
# Runner process to update the virus check signatures nightly basis
#

# source the helper...
DIR=$(dirname $0)
. $DIR/common.sh

# the time we want the action to occur
# this is specified in localtime
export ACTION_TIME="01:00"
export ACTION_TIMEZONE="America/New_York"

# helpful message...
logit "INFO: Virus check signature refresher starting up..."

# sleep for a bit so we do not do a refresh immediatly
sleep 60

# forever...
while true; do

   # starting message
   logit "INFO: Beginning virus check signature refresh sequence"

   rake libraoc:antivirus:refresh
   res=$?

   # ending message
   logit "INFO: Virus check signature refresh completes with status: $res"

   # sleep for another minute
   sleep 60

   # sleeping message...
   logit "INFO: Sleeping until $ACTION_TIME $ACTION_TIMEZONE..."
   sleep_until $ACTION_TIME $ACTION_TIMEZONE

done

# never get here...
exit 0

#
# end of file
#
