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
    apt-get install -y gawk wget sqlite3 patch xz-utils debianutils sudo libcurl3 && \
        apt-get install -y tcl && \
        apt-get install -y openssl libssl1.0.0 libreadline6 zlib1g libffi6 libgmp10 && \
        apt-get install -y libgl1-mesa-glx libglapi-mesa libxdmcp6 libpixman-1-0 xfonts-base x11-xserver-utils libjpeg8 && \
        apt-get install -y uuid netpbm iproute xauth \
                xkb-data x11-xkb-utils x11-apps x11-utils xterm software-properties-common && \
        apt-get install -y python-dateutil && \
        apt-get install -y man-db && \
        apt-get install -y dnsutils
}

install_base_prerequisites() {
    apt-get install -y lsof gcc unzip curl
}

install_build_prerequisites() {
    # git (and possibly others)
    # ruby
    # modules
    # genders
    # gridware
    # tigervnc: libSM-devel required only for building vncpasswd and vncconfig
    # xwd
    # pluginhook
    # pdsh
    apt-get install -y build-essential && \
        apt-get install -y libcurl4-openssl-dev libexpat1-dev tcl gettext && \
        apt-get install -y libreadline-dev zlib1g-dev libssl-dev libffi-dev && \
        apt-get install -y tcl8.6-dev && \
        apt-get install -y bison flex && \
        apt-get install -y libsqlite3-dev && \
        apt-get install -y cmake automake autoconf libtool \
                gettext zlib1g-dev \
                xorg-server-source xutils-dev\
                xfonts-utils xtrans-dev \
                libx11-dev libxext-dev libxfont-dev libxdmcp-dev \
                libxkbfile-dev libdrm-dev libjpeg8-dev \
                libgl1-mesa-dev libpixman-1-dev libfreetype6-dev \
                libssl-dev libgnutls-dev libpam0g-dev \
                libsm-dev \
                x11proto-xcmisc-dev x11proto-bigreqs-dev x11proto-randr-dev \
                x11proto-render-dev x11proto-video-dev x11proto-composite-dev \
                x11proto-record-dev x11proto-scrnsaver-dev x11proto-resource-dev && \
        apt-get install -y libxkbfile-dev && \
        apt-get install -y git golang && \
        apt-get install -y libreadline-dev libncurses5-dev
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
    shopt -s nullglob
    for a in /etc/skel/.bashrc /home/*/.bashrc /root/.bashrc; do
        sed -i -e 's/PS1/USER_PS1/g' $a
        cat <<EOF >> $a

# uncomment to apply USER_PS1 as your prompt; turned off by default in
# order to provide the Alces Clusterware default prompt.
#apply_user_prompt=yes

if [ -n "$apply_user_prompt" ]; then
    PS1="$USER_PS1"
fi
EOF
    done
    shopt -u nullglob
}
