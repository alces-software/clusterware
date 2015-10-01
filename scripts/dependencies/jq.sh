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
detect_jq() {
    [ -f "${target}/opt/jq/bin/jq" ]
}

fetch_jq() {
    title "Fetching jq"
    if fetch_handling_is_source; then
        fetch_source https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 "jq"
    else
        fetch_dist jq
    fi
}

install_jq() {
    title "Installing jq"
    if fetch_handling_is_source; then
        doing 'Install'
        mkdir -p "${target}"/opt/jq/bin
        cp "${dep_src}"/jq "${target}"/opt/jq/bin
        chmod 755 "${target}"/opt/jq/bin/jq
        say_done $?
    else
        install_dist jq
    fi
}
