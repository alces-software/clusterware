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
process_wait_for_pid() {
    local pid
    pid=$1
    while [ -d /proc/$pid ]; do
        sleep 5 &
        # Wait for the backgrounded sleep to complete. Running the sleep in the
        # background, allows this process to be responsive to any signals it
        # receives.
        wait $!
    done
}

process_reexec_sudo() {
    if [ "$UID" != "0" ]; then
        exec sudo "$0" "$@"
    fi
}
