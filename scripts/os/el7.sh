#==============================================================================
# Copyright (C) 2015-2016 Stephen F. Norledge and Alces Software Ltd.
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
install_runtime_prerequisites() {
    # ruby
    # alces template/howto
    # dns functions (dig)
    # uuid binary
    yum -e0 -y install openssl readline zlib libffi gmp && \
        yum -e0 -y install man && \
        yum -e0 -y install bind-utils && \
        yum -e0 -y install uuid
}

install_base_prerequisites() {
    yum -e0 -y install lsof gcc unzip sudo
}

install_build_prerequisites() {
    # git (and possibly others)
    # ruby
    # pluginhook
    yum -e0 -y groupinstall "Development Tools" && \
        yum -e0 -y install openssl-devel curl-devel expat-devel perl-ExtUtils-MakeMaker && \
        yum -e0 -y install openssl-devel readline-devel zlib-devel libffi-devel && \
        yum -e0 -y install git golang
}

install_startup_hooks() {
    for a in "${source}/dist/init/systemd"/*; do
        if [ "${a##*.}" == 'inactive' ]; then
            cp $a /etc/systemd/system/$(basename "$a" .inactive) || return 1
        else
            cp $a /etc/systemd/system && \
                systemctl enable "$(basename $a)" || \
                return 1
        fi
    done
}

install_distro_specific() {
    :
}
