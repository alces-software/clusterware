#!/bin/bash
if [ "$1" == "enable" ]; then
    yum install -y epel-release
else
    yum remove -y epel-release
fi
