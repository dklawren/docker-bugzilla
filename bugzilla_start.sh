#!/bin/bash
docker run -d -t --privileged \
    --name bugzilla \
    --hostname bugzilla \
    --publish 8080:80 \
    --publish 2222:22 \
    --volume /sys/fs/cgroup:/sys/fs/cgroup:ro \
    dklawren/docker-bugzilla 
