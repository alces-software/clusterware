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
detect_pdsh() {
    [ -d "${target}/opt/pdsh" ]
}

fetch_pdsh() {
    title "Fetching pdsh"
    if fetch_handling_is_source; then
        fetch_source "https://pdsh.googlecode.com/files/pdsh-2.29.tar.bz2" "pdsh-source.tar.bz2"
    else
        fetch_dist pdsh
    fi
}

install_pdsh() {
    title "Installing pdsh"
    if fetch_handling_is_source; then
        doing 'Extract'
        tar -C "${dep_build}" -xjf "${dep_src}/pdsh-source.tar.bz2"
        say_done $?

        cd "${dep_build}"/pdsh-*

        doing 'Configure'
        ./configure --prefix="${target}/opt/pdsh" --with-ssh \
            --with-rcmd-rank-list=ssh,rsh,exec \
            --with-genders \
            --with-readline \
            CPPFLAGS="-I${target}/opt/genders/include" \
            LDFLAGS="-L${target}/opt/genders/lib" \
            &> "${dep_logs}/pdsh-configure.log"
        say_done $?

        doing 'Compile'
        make &> "${dep_logs}/pdsh-make.log"
        say_done $?

        doing 'Install'
        make install &> "${dep_logs}/pdsh-install.log"
        say_done $?
    else
        install_dist pdsh
    fi
}
