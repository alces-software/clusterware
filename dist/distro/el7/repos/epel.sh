#!/bin/bash
if [ "$1" == "enable" ]; then
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
else
    yum remove -y epel-release
fi
