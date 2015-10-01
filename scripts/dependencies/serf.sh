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
detect_serf() {
    [ -f "${target}/opt/serf/bin/serf" ]
}

fetch_serf() {
    title "Fetching Serf"
    if fetch_handling_is_source; then
        fetch_source https://dl.bintray.com/mitchellh/serf/0.6.4_linux_amd64.zip serf-source.zip
    else
        fetch_dist serf
    fi
}

install_serf() {
    title "Installing Serf"
    if fetch_handling_is_source; then
        doing 'Extract'
        mkdir -p "${target}/opt/serf/bin"
        unzip -d "${target}/opt/serf/bin" "${dep_src}/serf-source.zip" &> "${dep_logs}/serf-install.log"
        say_done $?
    else
        install_dist serf
    fi
    # ubuntu/debian
    #adduser --system --disabled-password --disabled-login --home /nonexistent \
    #    --no-create-home --quiet --force-badname --group _serf
}
