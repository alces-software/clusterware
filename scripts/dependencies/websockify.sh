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
detect_websockify() {
    [ -d "${target}/opt/websockify" ]
}

fetch_websockify() {
    title "Fetching Websockify"
    if fetch_handling_is_source; then
        fetch_source https://github.com/kanaka/websockify/archive/v0.7.0.tar.gz websockify-source.tar.gz
    else
        fetch_dist websockify
    fi
}

install_websockify() {
    title "Installing Websockify"
    if fetch_handling_is_source; then
        doing 'Extract'
        tar -C "${dep_build}" -xzf "${dep_src}/websockify-source.tar.gz"
        say_done $?

        cd "${dep_build}"/websockify-*

        doing 'Install'
	mkdir -p "${target}/opt/websockify/lib"
	cat <<\EOF > "${target}"/opt/websockify/websockify
#!/bin/bash
pushd $(dirname "$BASH_SOURCE")/lib > /dev/null
exec ./run "$@"
EOF
	chmod 755 "${target}"/opt/websockify/websockify
	cp -R websockify run README.md LICENSE.txt docs "${target}"/opt/websockify/lib
        say_done $?
    else
        install_dist websockify
    fi
}
