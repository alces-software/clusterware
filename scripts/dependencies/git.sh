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
detect_git() {
    [ -d "${target}/opt/git" ]
}

fetch_git() {
    title "Fetching Git"
    if fetch_handling_is_source; then
        fetch_source https://www.kernel.org/pub/software/scm/git/git-2.5.2.tar.gz git-source.tar.gz
    else
        fetch_dist git
    fi
}

install_git() {
    title "Installing Git"
    if fetch_handling_is_source; then
        doing 'Extract'
        tar -C "${dep_build}" -xzf "${dep_src}/git-source.tar.gz"
        say_done $?

        cd "${dep_build}"/git-*

        doing 'Compile'
        make prefix="${target}/opt/git" all &> "${dep_logs}/git-make.log"
        say_done $?

        doing 'Install'
        make prefix="${target}/opt/git" install &> "${dep_logs}/git-install.log"
        say_done $?
    else
        install_dist git
    fi
}
