#!/bin/bash
if [ "$1" == "enable" ]; then
    if ! rpm -ql epel-release &>/dev/null; then
        yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
    fi
else
    if rpm -ql epel-release &>/dev/null; then
        yum remove -y epel-release
    fi
fi
