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
detect_libyaml() {
    [ -f "${target}/opt/lib/lib/libyaml.so" ]
}

fetch_libyaml() {
    title "Fetching LibYAML"
    if [ "$dep_source" == "fresh" ]; then
        fetch_source http://pyyaml.org/download/libyaml/yaml-0.1.5.tar.gz "yaml-source.tar.gz"
    else
        fetch_dist libyaml
    fi
}

install_libyaml() {
    title "Installing LibYAML"
    if [ "$dep_source" == "fresh" ]; then
        doing 'Extract'
        tar -C "${dep_build}" -xzf "${dep_src}/yaml-source.tar.gz"
        say_done $?

        cd "${dep_build}"/yaml-*

        doing 'Configure'
        ./configure --prefix="${target}/opt/lib" &> "${dep_logs}/libyaml-configure.log"
        say_done $?

        doing 'Compile'
        make &> "${dep_logs}/libyaml-make.log"
        say_done $?

        doing 'Install'
        make install &> "${dep_logs}/libyaml-install.log"
        say_done $?
    else
        install_dist libyaml
    fi
}
