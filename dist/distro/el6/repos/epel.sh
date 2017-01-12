#!/bin/bash
if [ "$1" == "enable" ]; then
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
else
    yum remove -y epel-release
fi
