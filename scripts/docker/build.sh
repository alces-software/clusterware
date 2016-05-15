#!/bin/bash
docker login
docker build --rm=true -t "alces/clusterware-el7:1.4.0" el7-1.4.0
docker push "alces/clusterware-el7:1.4.0"
docker build --rm=true -t "alces/clusterware-el6:1.4.0" el6-1.4.0
docker push "alces/clusterware-el6:1.4.0"
