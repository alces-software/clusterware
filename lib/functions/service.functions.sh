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
# An associative array of service descriptions to PIDs. Each service in this
# associative array will be killed when this process cleans up.
declare -A SERVICES

service_add() {
    local name pid
    name="$1"
    pid="$2"
    SERVICES[$name]=$pid
}

service_cleanup() {
    local name pid
    # Terminate each service in SERVICES.
    for name in "${!SERVICES[@]}"; do
        pid=${SERVICES[$name]}
        debug "Terminating ${name} process (${pid})"
        kill ${pid} &> /dev/null
    done
}
