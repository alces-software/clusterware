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
network_get_public_address() {
    local public_ipv4
    # Attempt to determine our public IP address using the standard EC2
    # API.
    public_ipv4=$(curl -f --connect-timeout 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)

    if [ -z "$public_ipv4" ]; then
        # Couldn't find it via EC2 API, use apparent public interface address.
        ip -o route get 8.8.8.8 \
            | head -n 1 \
            | sed 's/.*src \(\S*\).*/\1/g'
    else
        echo "$public_ipv4"
    fi
}

network_get_mapped_address() {
    local lookup lookup_type lookup_param mapping
    lookup="${1:-$(network_get_public_address)}"
    lookup_type="${2:-table}"
    # based on the given address, lookup an alternative
    case "$lookup_type" in
        table)
            lookup_param=${3:-access}
            if [ -f "${cw_ROOT}"/etc/mappingstab ]; then
                mapping=$(sed -rn "s/^${lookup}\s+${lookup_param}\s+(.*)/\1/gp" "${cw_ROOT}"/etc/mappingstab | head -n1)
            fi
            ;;
    esac
    if [ "${mapping}" ]; then
        echo "${mapping}"
    else
        echo "${lookup}"
    fi
}

network_get_network_address() {
    local target_ip
    target_ip="$1"

    ip -o route get "${target_ip}" \
        | head -n 1 \
        | sed 's/.*src \(\S*\).*/\1/g'
}

network_get_network_device() {
    local target_ip
    target_ip="$1"

    ip -o route get "${target_ip}" \
        | head -n 1 \
        | sed 's/.*dev \(\S*\).*/\1/g'
}

network_get_device_address() {
    local target_iface
    target_iface="$1"

    ip -o -4 address show dev ${target_iface} \
        | head -n 1 \
        | sed 's/.*inet \(\S*\)\/.*/\1/g'
}

network_get_free_port() {
    local port
    port="$1"
    while ss -tln | grep -q :${port}; do
        port=$((${port}+1))
    done
    echo $port
}
