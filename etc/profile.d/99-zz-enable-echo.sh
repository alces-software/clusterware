################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2018 Alces Software Ltd
##
################################################################################
stty echo
if [ -t 2 ]; then
    read -N128 -t0.1
fi
