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
detect_pluginhook() {
    [ -f "${target}/opt/pluginhook/bin/pluginhook" ]
}

fetch_pluginhook() {
    title "Fetching pluginhook"
    if fetch_handling_is_source; then
        fetch_source https://github.com/progrium/pluginhook/archive/7b91f7692d3ec494d4945f27d6b88864cd2f4bde.tar.gz pluginhook-source.tar.gz
    else
        fetch_dist pluginhook
    fi
}

install_pluginhook() {
    title "Installing pluginhook"
    if fetch_handling_is_source; then
        doing 'Extract'
        tar -C "${dep_build}" -xzf "${dep_src}/pluginhook-source.tar.gz"
        say_done $?

        cd "${dep_build}"/pluginhook-*

        doing 'Compile'
        mkdir -p build
        export GOPATH=$(pwd)/build
        go get "golang.org/x/crypto/ssh/terminal" &> "${dep_logs}/pluginhook-goget.log"
        go build -o pluginhook &> "${dep_logs}/pluginhook-compile.log"
        say_done $?

        doing 'Install'
        mkdir -p "${target}/opt/pluginhook/bin"
        cp pluginhook "${target}/opt/pluginhook/bin"
        say_done $?
    else
        install_dist pluginhook
    fi
}
