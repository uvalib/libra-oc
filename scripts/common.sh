#!/usr/bin/env bash
#
# common methods between the scripts
#

#
# log a message
#
function logit {
   local msg=$1
   echo "$msg"
}

#
# sleep until the provided time
#
function sleep_until {
   local target=$1
   local timezone=$2
   local current_time=$(TZ=$timezone date "+%H:%M")
   while [ $target != $current_time ]; do
      sleep 59
      current_time=$(TZ=$timezone date "+%H:%M")
   done
}

#
# end of file
#
