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
cw_MEMBER_DIR="${cw_ROOT}"/var/lib/members

member_register() {
    local member name host role tags

    # parse stdin for new member data
    member=($(cat))
    name="${member[0]}"
    host="${member[1]}"
    role="${member[2]}"
    tags="${member[3]}"

    if [ ! -f "${cw_MEMBER_DIR}"/"${name}" ]; then
        mkdir -p "${cw_MEMBER_DIR}"
        cat <<EOF > "${cw_MEMBER_DIR}"/"${name}"
cw_MEMBER_host="${host}"
cw_MEMBER_role="${role}"
cw_MEMBER_tags="${tags}"
EOF
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
    . "${cw_ROOT}"/etc/config/cluster.vars.sh
    echo "${cw_CLUSTER_QUORUM}"
}
