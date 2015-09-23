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
detect_xwd() {
    [ -d "${target}/opt/xwd" ]
}

fetch_xwd() {
    title "Fetching xwd"
    if [ "$dep_source" == "fresh" ]; then
        fetch_source http://xorg.freedesktop.org/archive/individual/app/xwd-1.0.6.tar.bz2 xwd-source.tar.bz2
    else
        fetch_dist xwd
    fi
}

install_xwd() {
    title "Installing xwd"
    if [ "$dep_source" == "fresh" ]; then
        doing 'Extract'
        tar -C "${dep_build}" -xjf "${dep_src}/xwd-source.tar.bz2"
        say_done $?

        cd "${dep_build}"/xwd-*
        doing 'Compile'
        ./configure --prefix="${target}/opt/xwd" &> "${dep_logs}/xwd-configure.log"
        make &> "${dep_logs}/xwd-make.log"
        say_done $?

        doing 'Install'
        make install &> "${dep_logs}/xwd-install.log"
        mkdir "${target}/opt/xwd/doc"
        cp COPYING "${target}/opt/xwd/doc"
        say_done $?
    else
        install_dist xwd
    fi
}
