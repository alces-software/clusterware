#==============================================================================
# Copyright (C) 2015 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Clusterware.
#
# Alces Clusterware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Clusterware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Clusterware, please visit:
# https://github.com/alces-software/clusterware
#==============================================================================
if [ -z "${cw_DIST}" ]; then
    source "${cw_ROOT}/etc/distro.rc"
fi

distro_enable_service() {
    local service
    service="$1"
    if [ "${cw_DIST}" == "el7" ]; then
        systemctl enable ${service}
    elif [ "${cw_DIST}" == "ubuntu1604" ]; then
        systemctl enable ${service}
    elif [ "${cw_DIST}" == "el6" ]; then
        chkconfig ${service} on
    fi
}

distro_disable_service() {
    local service
    service="$1"
    if [ "${cw_DIST}" == "el7" ]; then
        systemctl disable ${service}
    elif [ "${cw_DIST}" == "ubuntu1604" ]; then
        systemctl disable ${service}
    elif [ "${cw_DIST}" == "el6" ]; then
        chkconfig ${service} off
    fi
}

distro_start_service() {
    local service
    service="$1"
    if [ "${cw_DIST}" == "el7" ]; then
        systemctl --no-block start ${service}
    elif [ "${cw_DIST}" == "ubuntu1604" ]; then
        systemctl --no-block start ${service}
    elif [ "${cw_DIST}" == "el6" ]; then
        service ${service} start
    fi
}

distro_restart_service() {
    local service
    service="$1"
    if [ "${cw_DIST}" == "el7" ]; then
        systemctl --no-block restart ${service}
    elif [ "${cw_DIST}" == "ubuntu1604" ]; then
        systemctl --no-block restart ${service}
    elif [ "${cw_DIST}" == "el6" ]; then
        service ${service} restart
    fi
}

distro_is() {
    local dist
    dist="$1"
    [ "${cw_DIST}" == "${dist}" ]
}

distro_is_repository_permitted() {
    local name repo
    name="$1"
    for repo in "${cw_DIST_permit_repos[@]}"; do
	if [ "$repo" == "*" -o "$repo" == "$name" ]; then
	    return 0
	fi
    done
    return 1
}

distro_enable_repository() {
    distro_manage_repository enable "$@"
}

distro_disable_repository() {
    distro_manage_repository disable "$@"
}

distro_manage_repository() {
    local op name
    op="$1"
    name="$2"
    shift 2
    if distro_repository_exists "$name"; then
	if distro_is_repository_permitted "$name"; then
            "${cw_ROOT}"/etc/distro/repos/${name}.sh "${op}" "$@"
	else
	    echo "Prohibited repository: ${name}"
	    return 1
	fi
    else
	echo "Unknown repository: ${name}"
	return 1
    fi
}

distro_repository_exists() {
    local name
    name="$1"
    [ -x "${cw_ROOT}"/etc/distro/repos/${name}.sh ]
}
