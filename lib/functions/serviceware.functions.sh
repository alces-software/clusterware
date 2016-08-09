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
require distro

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

serviceware_build() {
    local repodir plugin distro builder exitcode
    repodir="${cw_SERVICEWARE_REPODIR}"
    plugin="$1"
    distro="$2"
    shift 2
    if [ -f "${repodir}/${plugin}/metadata.yml" ]; then
        builder="$(mktemp /tmp/clusterware-builder.XXXXXXXX.sh)"
        repo_generate_script "${repodir}/${plugin}" "${builder}" "${distro}" "build"
        cd "${cw_ROOT}"
        set -o pipefail
        /bin/bash "${builder}" "$@" 2>&1 | sed 's/^/  >>> /g'
        exitcode=$?
        set +o pipefail
        rm -f "${builder}"
        return $exitcode
    fi
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

serviceware_list_components() {
    local service components
    service="$1"
    components=()
    for a in $(repo_list_scripts "${cw_SERVICEWARE_REPODIR}/${service}"); do
        if [[ "$a" == "component-"* ]]; then
            components+=($(echo "$a" | cut -c11-))
        fi
    done
    echo "${components[@]}"
}

serviceware_add() {
    . "${cw_ROOT}"/etc/serviceware.rc
    local name registry_name src_name
    name="$1"
    registry_name="cw_SERVICE_registry_${name//-/_}"
    if [ "${!registry_name}" ]; then
	src_name="${!registry_name}"
    else
	src_name="${name}"
    fi
    {
        curl -# \
             -L "${cw_SERVICE_url}/${cw_DIST}"/${src_name}.tar.gz \
             2>&1 1>&3 3>&- | \
            stdbuf -oL \
                   bash -c \
                   "(tr '\r' '\n' | grep -Eo '[0-9]{2,3}\.[0-9]' | cut -f1 -d'.' | uniq -w1 | sed 's/\(.*\)/Progress: \1%/')";
    } 3>&1 1>&2 | tar -C "${cw_ROOT}" -xz
}
