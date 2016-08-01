#==============================================================================
# Copyright (C) 2015-2016 Stephen F. Norledge and Alces Software Ltd.
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
cw_MEMBER_DIR="${cw_ROOT}"/var/lib/members
cw_MEMBER_reader="${cw_ROOT}/opt/serf/bin/serf"

member_register() {
    local member name ip role tags

    # parse stdin for new member data
    member=($(cat))
    name="${member[0]}"
    ip="${member[1]}"
    role="${member[2]}"
    tags="${member[3]}"

    name=${name%%.*}
    if [ ! -f "${cw_MEMBER_DIR}"/"${name}" ]; then
        mkdir -p "${cw_MEMBER_DIR}"
        cat <<EOF > "${cw_MEMBER_DIR}"/"${name}"
cw_MEMBER_ip="${ip}"
cw_MEMBER_role="${role}"
cw_MEMBER_tags="${tags}"
EOF
    fi
}

member_parse() {
    local member name ip role tags

    # parse stdin for new member data
    member=($(cat))
    name="${member[0]}"
    ip="${member[1]}"
    role="${member[2]}"
    tags="${member[3]}"

    cat <<EOF
cw_MEMBER_name="${name}"
cw_MEMBER_ip="${ip}"
cw_MEMBER_role="${role}"
cw_MEMBER_tags="${tags}"
EOF
}

member_list() {
    if [ -f "${cw_ROOT}"/etc/config/cluster/auth.rc ]; then
        . "${cw_ROOT}"/etc/config/cluster/auth.rc
        "${cw_MEMBER_reader}" members \
            -rpc-auth="${cw_CLUSTER_auth_token}" | \
              sed -e 's/:7946//g' -e 's/\(.*\) alive \(.*role=\)\([^,]*\)/\1 \3 \2\3/g' \
              | awk '{print $1"\t"$2"\t"$3"\t"$4};'
    fi
}

member_unregister() {
    local member name
    member=($(cat))
    name="${member[0]}"
    if [ -f "${cw_MEMBER_DIR}"/"${name}" ]; then
        rm -f "${cw_MEMBER_DIR}"/"${name}"
    fi
}

member_count() {
    ls -A "${cw_MEMBER_DIR}" | wc -l
}

member_quorum() {
    . "${cw_ROOT}"/etc/config/cluster/cluster.vars.sh
    echo "${cw_CLUSTER_quorum}"
}

member_purge() {
    rm -rf "${cw_MEMBER_DIR}"/*
}

member_each() {
    local callback args base_args member
    callback="$1"
    shift
    base_args=("$@" --)
    shopt -s nullglob
    for member in "${cw_MEMBER_DIR}"/*; do
        args=("${base_args[@]}")
        args+=($(basename "$member"))
        . $member
        args+=("${cw_MEMBER_ip}" "${cw_MEMBER_role}" "${cw_MEMBER_tags}")
        ${callback} "${args[@]}"
    done
    shopt -u nullglob
}

member_load_vars() {
    local member
    member="$1"
    if [ ! -f "${cw_MEMBER_DIR}/${member}" ]; then
        member=${member%%.*}
    fi
    . "${cw_MEMBER_DIR}/${member}"
}

member_ip() {
    member_load_vars "$@"
    echo "${cw_MEMBER_ip}"
}

member_tags() {
    member_load_vars "$@"
    echo "${cw_MEMBER_tags}"
}

member_find_tag() {
    local needle haystack tags tag tuple key value
    needle="$1"
    haystack="$2"
    IFS=',' read -a tags <<< "${haystack}"
    for tag in "${tags[@]}"; do
        IFS='=' read -a tuple <<< "${tag}"
        key=${tuple[0]}
        value=${tuple[1]}
        if [ "$key" == "$needle" ]; then
            echo "${value}"
            break
        fi
    done
}

member_get_member_tag() {
    local member needle tags tag tuple key value
    member="$1"
    needle="$2"
    member_find_tag "${needle}" "$(member_tags ${member})"
}
