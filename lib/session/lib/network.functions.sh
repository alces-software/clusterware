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
    public_ipv4=$(curl --connect-timeout 5 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)

    if [ -z "$public_ipv4" ]; then
	# Couldn't find it via EC2 API, use apparent public interface address.
        ip route get 8.8.8.8 \
            | head -n 1 \
            | cut -d ' ' -f 8
    else
        echo "$public_ipv4"
    fi
}
