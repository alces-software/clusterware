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
detect_genders() {
    [ -d "${target}/opt/genders" ]
}

fetch_genders() {
    title "Fetching Genders"
    if [ "$dep_source" == "fresh" ]; then
        fetch_source "https://github.com/chaos/genders/releases/download/genders-1-22-1/genders-1.22.tar.gz" "genders-source.tar.gz"
    else
        fetch_dist genders
    fi
}

install_genders() {
    title "Installing genders"
    if [ "$dep_source" == "fresh" ]; then
        doing 'Extract'
        tar -C "${dep_build}" -xzf "${dep_src}/genders-source.tar.gz"
        say_done $?

        cd "${dep_build}"/genders-*

        doing 'Configure'
        ./configure --prefix="${target}/opt/genders" \
            --with-genders-file="${target}/etc/genders" \
            --without-java-extensions \
            --without-perl-extensions \
            --without-python-extensions \
            &> "${dep_logs}/genders-configure.log"
        say_done $?

        doing 'Compile'
        patch -p0 < ${source}/scripts/dependencies/patches/genders/genders-file-envvar.patch \
            &> "${dep_logs}/genders-file-envvar-patch.log"
        make &> "${dep_logs}/genders-make.log"
        say_done $?

        doing 'Install'
        make install &> "${dep_logs}/genders-install.log"
        say_done $?
    else
        install_dist genders
    fi
}
