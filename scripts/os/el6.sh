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
    # alces gridware
    # modules
    # ruby
    # tigervnc
    # alces session
    # s3cmd
    # alces template/howto
    # dns functions (dig)
    yum -e0 -y install wget sqlite3 patch bzip2 xz-utils file which sudo && \
        yum -e0 -y install tcl && \
        yum -e0 -y install openssl readline zlib libffi gmp && \
        yum -e0 -y install mesa-libGL libXdmcp pixman xorg-x11-fonts-misc && \
        yum -e0 -y install uuid netpbm-progs iproute xauth \
          xkeyboard-config xorg-x11-xkb-utils xorg-x11-apps xorg-x11-server-utils xterm && \
        yum -e0 -y install python-dateutil && \
        yum -e0 -y install man \
        yum -e0 -y install bind-utils
}

install_base_prerequisites() {
    yum -e0 -y install lsof gcc unzip
}

install_build_prerequisites() {
    # git (and possibly others)
    # ruby
    # modules
    # gridware
    # tigervnc: libSM-devel required only for building vncpasswd and vncconfig
    # xwd
    # pluginhook
    yum -e0 -y groupinstall "Development Tools" && \
        yum -e0 -y install openssl-devel curl-devel expat-devel perl-ExtUtils-MakeMaker && \
        yum -e0 -y install openssl-devel readline-devel zlib-devel libffi-devel && \
        yum -e0 -y install tcl-devel && \
        yum -e0 -y install sqlite-devel && \
        yum -e0 -y install cmake automake autoconf libtool \
        gettext gettext-devel zlib-devel \
        xorg-x11-server-source xorg-x11-util-macros \
        xorg-x11-font-utils xorg-x11-xtrans-devel \
        libX11-devel libXext-devel libXfont-devel libXdmcp-devel \
        libxkbfile-devel libdrm-devel libjpeg-turbo-devel \
        mesa-libGL-devel pixman-devel freetype-devel \
        openssl-devel gnutls-devel pam-devel \
        libSM-devel && \
        yum -e0 -y install libxkbfile-devel && \
        yum -e0 -y install epel-release && \
        yum -e0 -y install git golang
}

install_startup_hooks() {
    local target_init_script
    for a in "${source}/dist/init/sysv"/*.el6; do
        target_init_script="$(basename "$a" .el6)"
        if [ "${target_init_script##*.}" == 'inactive' ]; then
            cp $a /etc/init.d/$(basename "${target_init_script}" .inactive) && \
                chmod 755 /etc/init.d/$(basename "${target_init_script}" .inactive) || \
                return 1
        else
            cp $a /etc/init.d/${target_init_script} && \
                chmod 755 /etc/init.d/${target_init_script} && \
                chkconfig "${target_init_script}" on || \
                return 1
        fi
    done
}

install_distro_specific() {
    :
}
