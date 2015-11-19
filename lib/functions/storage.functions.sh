#!/bin/bash
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
require repo
require xdg

cw_STORAGE_REPODIR="${cw_ROOT}/var/lib/storage/repos"
cw_STORAGE_PLUGINDIR="${cw_ROOT}/etc/storage"
cw_STORAGE_DEFAULT_REPO="base"
cw_STORAGE_DEFAULT_REPO_URL="${cw_STORAGE_DEFAULT_REPO_URL:-https://:@github.com/alces-software/clusterware-storage}"

storage_is_enabled() {
    repo_plugin_is_enabled "${cw_STORAGE_PLUGINDIR}" "$@"
}

storage_repo_exists() {
    repo_exists "${cw_STORAGE_REPODIR}" "$@"
}

storage_exists() {
    repo_plugin_exists "${cw_STORAGE_REPODIR}" "$@"
}

storage_install() {
    repo_plugin_install "${cw_STORAGE_REPODIR}" "$@"
}

storage_enable() {
    repo_plugin_enable "${cw_STORAGE_REPODIR}" "${cw_STORAGE_PLUGINDIR}" "$@"
}

storage_type_for() {
    local name cfg
    name="$1"
    cfg=$(storage_get_configuration "${name}")
    cfg="${cfg%.*}"
    echo "${cfg##*.}"
}

storage_load_functions() {
    local type
    type="$1"
    if [ -f "${cw_STORAGE_PLUGINDIR}"/${type}/${type}-storage.functions.sh ]; then
        . "${cw_STORAGE_PLUGINDIR}"/${type}/${type}-storage.functions.sh
    else
        return 1
    fi
}

storage_configure() {
    local type name system
    if [ "$1" == "--system" ]; then
        system="$1"
        shift
    fi
    type="$1"
    name="$2"
    shift
    if storage_configuration_exists "${name}"; then
        echo "configuration already exists for '${name}'"
        return 1
    elif storage_load_functions "${type}"; then
        if ${type}_storage_configure ${system} "$@"; then
            if [ -z "${system}" -a -z "$(storage_default_configuration)" ]; then
                storage_set_default_configuration "${name}"
            fi
        fi
    else
        echo "couldn't find storage backend for type: ${type}"
        return 1
    fi
}

storage_write_configuration() {
    local name dir path system
    if [ "$1" == "--system" ]; then
        system="$1"
        shift
    fi
    name="$1"

    if storage_configuration_exists "$@"; then
        return 1
    fi

    if [ "${system}" ]; then
        dir="$(xdg_config_dirs | cut -f1 -d:)"/clusterware/storage
    else
        dir="$(xdg_config_home)"/clusterware/storage
    fi

    path="${dir}"/"${name}"

    mkdir -p "${dir}"
    touch "${path}"
    if [ -z "${system}" ]; then
        chmod 0600 "${path}"
    fi
    cat > "${path}"
}

storage_each_configuration() {
    local fn user_path sys_path paths a
    fn="$1"

    sys_path="$(xdg_search "$(xdg_config_dirs)" "clusterware/storage")"
    if [ "${sys_path}" ]; then
        paths=("${sys_path}"/*)
        if [ "${paths}" != "${sys_path}/*" ]; then
            for a in "${paths[@]}"; do
                if [ "${a##*.}" != "yml" ]; then
                    $fn "${a}"
                fi
            done
        fi
    fi

    user_path="$(xdg_config_home)"/clusterware/storage
    paths=("${user_path}"/*)
    if [ "${paths}" != "${user_path}/*" ]; then
        for a in "${paths[@]}"; do
            if [ "${a##*.}" != "yml" ]; then
                $fn "${a}"
            fi
        done
    fi

}

storage_get_configuration() {
    local user_path sys_path paths a
    sys_path="$(xdg_search "$(xdg_config_dirs)" "clusterware/storage")"
    if [ "${sys_path}" ]; then
        paths=("${sys_path}"/"$1".*)
        if [ "${paths}" != "${sys_path}/$1.*" ]; then
            for a in "${paths[@]}"; do
                if [ "${a##*.}" != "yml" ]; then
                    echo "$a"
                    return 0
                fi
            done
        fi
    fi

    user_path="$(xdg_config_home)"/clusterware/storage/"$1"
    paths=("${user_path}".*)
    if [ "${paths}" != "${user_path}.*" ]; then
        for a in "${paths[@]}"; do
            if [ "${a##*.}" != "yml" ]; then
                echo "$a"
                return 0
            fi
        done
    fi
}

storage_configuration_exists() {
    local user_path sys_path paths a
    sys_path="$(xdg_search "$(xdg_config_dirs)" "clusterware/storage")"
    if [ "${sys_path}" ]; then
        paths=("${sys_path}"/"$1".*)
        if [ "${paths}" != "${sys_path}/$1.*" ]; then
            return 0
        fi
    fi

    user_path="$(xdg_config_home)"/clusterware/storage/"$1"
    paths=("${user_path}".*)
    if [ "${paths}" != "${user_path}.*" ]; then
        return 0
    fi
    return 1
}

storage_forget_configuration() {
    local name path paths
    name="$1"
    path="$(xdg_config_home)"/clusterware/storage/"${name}"
    paths=("${path}".*)
    if [ "${paths}" != "${path}.*" ]; then
        rm -f "${path}".*
    else
        return 1
    fi
}

storage_default_configuration() {
    local name
    rc="$(xdg_config_search clusterware/storage.rc)"
    if [ -f "${rc}" ]; then
        . "${rc}"
        echo "${cw_STORAGE_default}"
    fi
}

storage_set_default_configuration() {
    local name system
    if [ "$1" == "--system" ]; then
        system=true
        shift
    fi
    name="$1"
    if [ "${system}" ]; then
        dir="$(xdg_config_dirs | cut -f1 -d:)"/clusterware
    else
        dir="$(xdg_config_home)"/clusterware
    fi
    mkdir -p "${dir}"
    echo "cw_STORAGE_default=\"${name}\"" > "${dir}"/storage.rc
}
