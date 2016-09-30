#==============================================================================
# Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
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
detect_xxd() {
    [ -d "${target}/opt/xxd" ]
}

fetch_xxd() {
    title "Fetching xxd"
    if fetch_handling_is_source; then
        fetch_source https://github.com/ThatOtherPerson/xxd/archive/master.tar.gz "xxd-source.tar.gz"
    else
        fetch_dist xxd
    fi
}

install_xxd() {
    title "Installing xxd"
    if fetch_handling_is_source; then
        doing 'Extract'
        tar -C "${dep_build}" -xzf "${dep_src}/xxd-source.tar.gz"
        say_done $?

        cd "${dep_build}"/xxd-*

        doing 'Compile'
        make &> "${dep_logs}/xxd-make.log"
        say_done $?

        doing 'Install'
        mkdir -p "${target}"/opt/xxd/{bin,man/man1}
        cp xxd "${target}"/opt/xxd/bin
        cp xxd.1 "${target}"/opt/xxd/man/man1
        say_done $?
    else
        install_dist xxd
    fi
}
