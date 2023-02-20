#if [ -z "$DOCKER_HOST" ]; then
#   echo "ERROR: no DOCKER_HOST defined"
#   exit 1
#fi

if [ -z "$DOCKER_HOST" ]; then
   DOCKER_TOOL=docker
else
   DOCKER_TOOL=docker-17.04.0
fi

# set the definitions
DOCKER_ENV=""

$DOCKER_TOOL run -t -i -p 8080:8080 $DOCKER_ENV uvadave/libra-oc /bin/bash -l
