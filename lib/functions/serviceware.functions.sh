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
require ruby
require repo

cw_SERVICEWARE_REPODIR="${cw_ROOT}/var/lib/services/repos"
cw_SERVICEWARE_PLUGINDIR="${cw_ROOT}/etc/services"
cw_SERVICEWARE_DEFAULT_REPO="base"
cw_SERVICEWARE_DEFAULT_REPO_URL="${cw_SERVICEWARE_DEFAULT_REPO_URL:-https://:@github.com/alces-software/clusterware-services}"

serviceware_run_hook() {
    local event
    event="$1"
    shift
    "$cw_SERVICEWARE_HOOK_RUNNER" "$event" "$@"
}

serviceware_is_enabled() {
    repo_plugin_is_enabled "${cw_SERVICEWARE_PLUGINDIR}" "$@"
}

serviceware_is_installed() {
    local name
    name="$1"
    [ -d "${cw_ROOT}"/opt/"${name}" ]
}

serviceware_repo_exists() {
    repo_exists "${cw_SERVICEWARE_REPODIR}" "$@"
}

serviceware_exists() {
    repo_plugin_exists "${cw_SERVICEWARE_REPODIR}" "$@"
}

serviceware_install() {
    repo_plugin_install "${cw_SERVICEWARE_REPODIR}" "$@"
}

serviceware_enable_component() {
    local service component distro
    service="$1"
    component="$2"
    distro="$3"
    shift 3

    if [ -f "${cw_SERVICEWARE_REPODIR}/${service}/metadata.yml" ]; then
        installer="$(mktemp /tmp/clusterware-installer.XXXXXXXX.sh)"
        repo_generate_script "${cw_SERVICEWARE_REPODIR}/${repodir}/${service}" "${installer}" "${distro}" "component-${component}"
        cd "${cw_ROOT}"
        set -o pipefail
        /bin/bash "${installer}" "$@" 2>&1 | sed 's/^/  >>> /g'
        exitcode=$?
        set +o pipefail
        rm -f "${installer}"
        if [ $exitcode -gt 0 ]; then
            return $exitcode
        else
            touch "${cw_SERVICEWARE_PLUGINDIR}/$(basename ${service})-${component}"
        fi
    fi
}

serviceware_has_component() {
    local service component
    service="$1"
    component="$2"

    repo_has_script "${cw_SERVICEWARE_REPODIR}/${service}" "component-${component}"
}
