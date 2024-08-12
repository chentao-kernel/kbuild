#!/bin/bash

groups | grep docker
NEED_SUDO=$?

if [ $NEED_SUDO -eq 1 ]; then
	echo "Hey, we gonna use sudo for running docker"
	SUDO_CMD="sudo"
else
	echo "Hey, you are in docker group, sudo is not needed"
	SUDO_CMD=""
fi

set -x

#$SUDO_CMD docker rm `sudo docker ps -a -q`

for image in $($SUDO_CMD docker images | grep "kernel-build-container" | awk '{print $3}')
do
	echo "rm image:$image"
	$SUDO_CMD docker rmi $image
done

$SUDO_CMD docker ps -a
$SUDO_CMD docker image ls
