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
    local public_ipv4 tmout
    tmout=${1:-5}
    if [ "${tmout}" -gt 0 ]; then
        # Attempt to determine our public IP address using the standard EC2
        # API.
        public_ipv4=$(network_fetch_ec2_metadata public-ipv4 ${tmout})
    fi

    if [ -z "$public_ipv4" ]; then
        # Couldn't find it via EC2 API, use apparent public interface address.
        ip -o route get 8.8.8.8 \
            | head -n 1 \
            | sed 's/.*src \(\S*\).*/\1/g'
    else
        echo "$public_ipv4"
    fi
}

network_get_public_hostname() {
    local public_hostname tmout dig_tmout
    tmout=${1:-5}
    if [ "${tmout}" -gt 0 ]; then
        # Attempt to determine our public DNS name using the standard EC2
        # API.
        public_hostname=$(network_fetch_ec2_metadata public-hostname ${tmout})
        dig_tmout=${tmout}
    else
        dig_tmout=1
    fi

    if [ -z "$public_hostname" ]; then
        # Couldn't find it via EC2 API, try a reverse lookup of public IP.
        public_hostname=$(dig +time=${dig_tmout} +short -x $(network_get_public_address ${tmout}) 2>/dev/null)
        public_hostname="${public_hostname%?}"
    fi
    echo "$public_hostname"
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

network_get_route_iface() {
    local target_ip
    target_ip="$1"

    ip -o route get "${target_ip}" \
        | head -n 1 \
        | sed 's/.*dev \(\S*\).*/\1/g'
}

network_get_first_iface() {
    ip -o link show \
        | grep -v 'lo:' \
        | head -n1 \
        | sed 's/^.: \(\S*\):.*/\1/g'
}

network_get_iface_address() {
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

network_has_metadata_service() {
    local tmout
    tmout="${1:-5}"
    [ "$cw_TEST_metadata_service" == "true" ] ||
        curl -f --connect-timeout $tmout http://169.254.169.254/ &>/dev/null
}

network_get_iface_network() {
    local target_iface
    target_iface="$1"

    ip -o -4 route show dev ${target_iface} \
        | head -n 1 \
        | sed 's/\(\S*\).*/\1/g'
}

# Adapted from https://forums.gentoo.org/viewtopic-t-888736-start-0.html
network_cidr_to_mask() {
   set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
   [ $1 -gt 1 ] && shift $1 || shift
   echo ${1-0}.${2-0}.${3-0}.${4-0}
}

network_is_ec2() {
    [ "${cw_TEST_ec2}" == "true" ] ||
        [ -f /sys/hypervisor/uuid -a "$(head -c3 /sys/hypervisor/uuid)" == "ec2" ]
}

network_fetch_ec2_document() {
    if [ "$cw_TEST_mock_ec2_document" ]; then
        cat <<EOF
{
  "region": "eu-west-1",
  "pendingTime": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "instanceId": "i-$(hostname | md5sum | cut -c1-8)",
  "accountId": "1234567890"
}
EOF
    else
        curl -s http://169.254.169.254/latest/dynamic/instance-identity/document
    fi
}

network_fetch_ec2_metadata() {
    local item tmout
    item="$1"
    tmout="${2:-5}"
    if [ "$cw_TEST_metadata_service" == "true" ]; then
        itemvar=cw_TEST_mock_ec2_$(echo "${item}" | tr '-' '_')
        if [ "${!itemvar}" ]; then
            echo "${!itemvar}"
        else
            return 1
        fi
    else
        curl -f --connect-timeout ${tmout} http://169.254.169.254/latest/meta-data/${item} 2>/dev/null       
    fi
}

network_ec2_hashed_account() {
    local account
    account=$(network_fetch_ec2_document | \
                     "${cw_ROOT}"/opt/jq/bin/jq -r .accountId)
    echo -n "${account}" | md5sum | cut -f1 -d' ' | base64 | cut -c1-16 | tr 'A-Z' 'a-z'
}

network_fetch_ec2_userdata() {
    tmout="${1:-5}"
    if network_has_metadata_service $tmout; then
        if [ "${cw_TEST_mock_ec2_userdata}" == "true" ]; then
            cat <<EOF
#cloud-config
#=FlightCustomizer ${cw_TEST_flight_customizer}
system_info:
  default_user:
    name: admin
hostname: login1
write_files:
- content: |
    cluster:
      uuid: '11111111-2222-3333-444444444444'
      token: '1A0a1aaAA1aAAA/aaa1aAA=='
      name: mockcluster
      role: 'master'
      tags:
        scheduler_roles: ':master:'
        storage_roles: ':master:'
        access_roles: ':master:'
  owner: root:root
  path: /opt/clusterware/etc/config.yml
  permissions: '0640'
EOF
        else
            curl -f --connect-timeout ${tmout} http://169.254.169.254/latest/user-data
        fi
    fi
}
