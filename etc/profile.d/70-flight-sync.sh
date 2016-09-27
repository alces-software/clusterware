################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2016 Alces Software Ltd
##
################################################################################
if [ "$UID" != "0" -a ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/clusterware/sync.rc" ]; then
    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/clusterware"
    cat <<EOF > "${XDG_CONFIG_HOME:-$HOME/.config}/clusterware/sync.rc"
################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2016 Alces Software Ltd
##
################################################################################
EOF
    if [ -f "${cw_ROOT}"/skel/sync.default.yml ]; then
        cp "${cw_ROOT}"/skel/sync.default.yml "${XDG_CONFIG_HOME:-$HOME/.config}/clusterware/sync.default.yml"
    else
        cat <<EOF > "${XDG_CONFIG_HOME:-$HOME/.config}/clusterware/sync.default.yml"
---
:source: :home
:encrypt:
- ".ssh/id_*"
- ".config/clusterware/storage*"
EOF
    fi
    eval $(cat "${cw_ROOT}"/etc/sync.rc | grep ^cw_SYNC_default=)
    if [ "$cw_SYNC_default" == "true" ]; then
        "${cw_ROOT}"/bin/alces sync pull --ignore-missing default
    fi
    unset cw_SYNC_default
fi
