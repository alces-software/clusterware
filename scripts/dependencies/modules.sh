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
detect_modules() {
    [ -d "${target}/opt/Modules" ]
}

fetch_modules() {
    title "Fetching Environment Modules"
    if [ "$dep_source" == "fresh" ]; then
        fetch_source "http://downloads.sourceforge.net/project/modules/Modules/modules-3.2.10/modules-3.2.10.tar.gz?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fmodules%2Ffiles%2FModules%2Fmodules-3.2.10%2F&ts=1415873248&use_mirror=switch" "modules-source.tar.gz"
    else
        fetch_dist modules
    fi
}

install_modules() {
    title "Installing Environment Modules"
    if [ "$dep_source" == "fresh" ]; then
        doing 'Extract'
        tar -C "${dep_build}" -xzf "${dep_src}/modules-source.tar.gz"
        say_done $?

        cd "${dep_build}"/modules-*

        doing 'Configure'
        if [ -f /usr/lib64/tclConfig.sh ]; then
            TCLLIB=/usr/lib64
        else
            TCLLIB=/usr/lib
        fi
        ./configure --disable-versioning --with-tcl=$TCLLIB \
            --prefix="${target}/opt" \
            &> "${dep_logs}/modules-configure.log"
        say_done $?

        doing 'Compile'
        make CFLAGS="-DUSE_INTERP_ERRORLINE" &> "${dep_logs}/modules-make.log"
        say_done $?

        doing 'Install'
        make install &> "${dep_logs}/modules-install.log"
        say_done $?
    else
        install_dist modules
    fi
}
