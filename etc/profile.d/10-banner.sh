if [[ "$0" == '-'* || "$1" == "force" ]] || shopt -q login_shell; then
    # this is a login shell, so we show a login message
    if [ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/clusterware/settings.rc.ex" ]; then
      mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/clusterware"
      cat <<EOF > "${XDG_CONFIG_HOME:-$HOME/.config}/clusterware/settings.rc.ex"
################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
##
################################################################################
# Rename this file to settings.rc to activate.
#===============================================================================
#
# Set the theme used by Clusterware tools. Options are: standard, light, dark
# Choose 'light' for a light-colored terminal, 'dark' for a dark-colored terminal.
#cw_SETTINGS_theme=dark
#
# The following options suppress various parts of the login banners:
#
# Set to true to stop display of the Alces Flight logo, cluster
# name and version information.
#cw_SETTINGS_skip_banner=true
#
# Set to true to stop display of "tips" and other MOTD content.
#cw_SETTINGS_skip_motd=true
#
# Set to true to stop display of cluster initialization status information.
#cw_SETTINGS_skip_status=true
EOF
    fi
    IFS=: read -a xdg_config <<< "${XDG_CONFIG_HOME:-$HOME/.config}:${XDG_CONFIG_DIRS:-/etc/xdg}"
    for a in "${xdg_config[@]}"; do
      if [ -e "${a}"/clusterware/settings.rc ]; then
        source "${a}"/clusterware/settings.rc
        break
      fi
    done
    unset xdg_config a
    # Respect .hushlogin setting
    if [ ! -f "$HOME/.hushlogin" ]; then
      if [ -f "${cw_ROOT}"/etc/config/cluster/config.rc ]; then
        eval $(grep '^cw_CLUSTER_name=' "${cw_ROOT}"/etc/config/cluster/config.rc)
      fi
      if [ -f "${cw_ROOT}"/etc/clusterware.rc ]; then
        eval $(egrep '^cw_(VERSION|STATUS)=' "${cw_ROOT}"/etc/clusterware.rc)
      fi
      if [ -f "${cw_ROOT}"/etc/config/cluster/instance.rc ]; then
        eval $(egrep '^cw_INSTANCE_role=' "${cw_ROOT}"/etc/config/cluster/instance.rc)
        eval $(egrep '^cw_INSTANCE_tag_CLUSTER_ROLES=' "${cw_ROOT}"/etc/config/cluster/instance.rc)
      else
        # default to master-type behaviour if no configuration has been found yet.
        cw_INSTANCE_role=master
      fi

      cw_DISTRO='unknown distro'
      if [ -f "${cw_ROOT}"/etc/distro.rc ]; then
        . "${cw_ROOT}"/etc/distro.rc
        if [[ "$cw_DIST" == "el6" || "$cw_DIST" == "el7" ]]; then
          cw_DISTRO="$(sed 's/\(.*\) release \(.*\) .*/\1 \2/g' /etc/redhat-release)"
        elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
          cw_DISTRO="$(grep ^DISTRIB_DESCRIPTION /etc/lsb-release | cut -f2 -d'"')"
        fi
      fi

      if [ "${cw_SETTINGS_skip_banner:-false}" == "false" ]; then
        export cw_ROOT
        if [ "$cw_INSTANCE_role" == "master" ] || [[ "${cw_INSTANCE_tag_CLUSTER_ROLES}" == *":login:"* ]]; then
          "${cw_ROOT}"/libexec/share/banner "${cw_CLUSTER_name:-your cluster}" "${cw_VERSION}" "$cw_DISTRO"
        else
          "${cw_ROOT}"/libexec/share/banner --short "${cw_CLUSTER_name:-your cluster}" "${cw_VERSION}" "$cw_DISTRO"
        fi
      fi
      if [[ "${cw_SETTINGS_skip_motd:-false}" == "false" && "$cw_INSTANCE_role" == "master" || "${cw_INSTANCE_tag_CLUSTER_ROLES}" == *":login:"* ]]; then
        if [ -d "${cw_ROOT}"/etc/motd.d ]; then
          for a in "${cw_ROOT}"/etc/motd.d/*; do
            if [ -f "$a" ]; then
              if [ "${a##*.}" == "sh" ]; then
                . "$a"
              elif [ "${a##*.}" == "txt" ]; then
                grep -v '^#' "$a"
              fi
            fi
          done
        fi
        if [ -f "${cw_ROOT}"/etc/motd ]; then
          grep -v '^#' ${cw_ROOT}/etc/motd
          echo ""
        fi
      fi

      unset cw_INSTANCE_role cw_CLUSTER_name cw_RELEASE cw_STATUS cw_INSTANCE_tag_CLUSTER_ROLES
    fi
    unset cw_SETTINGS_skip_motd cw_SETTINGS_skip_banner cw_SETTINGS_skip_status
    export cw_SETTINGS_theme
fi
