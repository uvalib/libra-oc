#
# Runner process to update the virus check signatures nightly basis
#

# source the helper...
DIR=$(dirname $0)
. $DIR/common.sh

# set the appropriate logger
export NAME=$(basename $0 .sh)
export LOGGER=$(logger_name "$NAME.log")

# the time we want the action to occur
# this is the time in EST
#export ACTION_TIME="01:00"
# we are running in UTC
export ACTION_TIME="05:00"

# helpful message...
logit "Virus check signature refresher starting up..."

# forever...
while true; do

   # starting message
   logit "Beginning virus check signature refresh sequence"

   rake libraoc:antivirus:refresh >> $LOGGER 2>&1
   res=$?

   # ending message
   logit "Virus check signature refresh completes with status: $res"

   # sleep for another minute
   sleep 60

   # sleeping message...
   logit "Sleeping until $ACTION_TIME..."
   sleep_until $ACTION_TIME

done

# never get here...
exit 0

#
# end of file
#