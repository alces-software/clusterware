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
detect_jo() {
    [ -d "${target}/opt/jo" ]
}

fetch_jo() {
    title "Fetching jo"
    if fetch_handling_is_source; then
        fetch_source https://github.com/jpmens/jo/releases/download/v1.0/jo-1.0.tar.gz "jo-source.tar.gz"
    else
        fetch_dist jo
    fi
}

install_jo() {
    title "Installing jo"
    if fetch_handling_is_source; then
        doing 'Extract'
        tar -C "${dep_build}" -xzf "${dep_src}/jo-source.tar.gz"
        say_done $?

        cd "${dep_build}"/jo-*

        doing 'Configure'
        ./configure --prefix="${target}/opt/jo" &> "${dep_logs}/jo-configure.log"
        say_done $?

        doing 'Compile'
        make &> "${dep_logs}/jo-make.log"
        say_done $?

        doing 'Install'
        make install &> "${dep_logs}/jo-install.log"
        say_done $?
    else
        install_dist jo
    fi
}
