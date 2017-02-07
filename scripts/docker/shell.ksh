if [ -z "$DOCKER_HOST" ]; then
   echo "ERROR: no DOCKER_HOST defined"
   exit 1
fi

# environment attributes

DOCKER_ENV=""

docker run -t -i -p 8130:3000 $DOCKER_ENV uvadave/libra-oc /bin/bash -l
