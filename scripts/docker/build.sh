#!/bin/bash
if [ -z "$1" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi
version=$1
docker login
docker build --rm=true -t "alces/clusterware-el7:${version}" el7-${version}
docker push "alces/clusterware-el7:${version}"
docker build --rm=true -t "alces/clusterware-el6:${version}" el6-${version}
docker push "alces/clusterware-el6:${version}"
