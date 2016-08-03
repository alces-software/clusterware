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
detect_tigervnc() {
    [ -d "${target}/opt/tigervnc" ]
}

fetch_tigervnc() {
    title "Fetching TigerVNC"
    if fetch_handling_is_source; then
        if [ "$os" == "ubuntu1604" ]; then
            fetch_source https://github.com/TigerVNC/tigervnc/archive/v1.6.90.tar.gz tigervnc-source.tar.gz
        else
            fetch_source https://github.com/TigerVNC/tigervnc/archive/v1.5.0.tar.gz tigervnc-source.tar.gz
        fi
    else
        fetch_dist tigervnc
    fi
}

install_tigervnc() {
    title "Installing TigerVNC"
    if fetch_handling_is_source; then
        local topdir

        doing 'Extract'
        tar -C "${dep_build}" -xzf "${dep_src}/tigervnc-source.tar.gz"
        say_done $?

        cd "${dep_build}"/tigervnc-*
        topdir=$(pwd)

        doing 'Compile'
        # patch FLTK requirement out of CMakeLists.txt and vncviewer/CMakeLists.txt
        patch -p1 < ${source}/scripts/dependencies/patches/tigervnc/remove-fltk-requirement.patch \
            &> "${dep_logs}/tigervnc-cmake-patch.log"
        cmake -G "Unix Makefiles" -DFLTK_FOUND=1 \
            -DCMAKE_INSTALL_PREFIX="${target}/opt/tigervnc" &> "${dep_logs}/tigervnc-cmake.log"
        cd "${topdir}/common"
        make &> "${dep_logs}/tigervnc-common-make.log"
        cd "${topdir}/unix/vncpasswd"
        make &> "${dep_logs}/tigervnc-vncpasswd-make.log"
        cd "${topdir}/unix/vncconfig"
        make &> "${dep_logs}/tigervnc-vncconfig-make.log"
        cd "${topdir}/unix/xserver"
        if [ -f /usr/src/xorg-server.tar.xz ]; then
            tar --strip-components=1 -xJf /usr/src/xorg-server.tar.xz
            patch -p1 < ${source}/scripts/dependencies/patches/tigervnc/xserver118.patch &> "${dep_logs}/tigervnc-xserver-patch.log"
            build_args=()
        elif [ -d /usr/share/xorg-x11-server-source ]; then
            cp -R /usr/share/xorg-x11-server-source/* .
            patch -p1 < ../xserver115.patch &> "${dep_logs}/tigervnc-xserver-patch.log"
            build_args=(--disable-config-dbus --enable-install-libxf86config)
        else
            echo "Can't find xorg source."
        fi
        # patch hw/vnc/xorg-version.h for 115
        # patch 'EXTRAS' out of hw/xwin/glx/Makefile.am
        #patch -p3 < ../../../xserver-fixes.patch
        autoreconf -fiv &> "${dep_logs}/tigervnc-xserver-autoreconf.log"
        ./configure --with-pic --without-dtrace --disable-static --disable-dri \
            --disable-xinerama --disable-xvfb --disable-xnest --disable-xorg \
            --disable-dmx --disable-xwin --disable-xephyr --disable-kdrive \
            --disable-config-hal --disable-config-udev \
            --disable-dri2 --disable-present \
            --disable-unit-tests \
            --enable-glx \
            --with-default-font-path="catalogue:/etc/X11/fontpath.d,built-ins" \
            --with-fontrootdir=/usr/share/X11/fonts \
            --with-xkb-path=/usr/share/X11/xkb \
            --with-xkb-output=/var/lib/xkb \
            --with-xkb-bin-directory=/usr/bin \
            --with-serverconfig-path=/usr/lib64/xorg \
            "${build_args[@]}" \
            --prefix="${target}/opt/tigervnc" \
            &> "${dep_logs}/tigervnc-xserver-configure.log"
        make &> "${dep_logs}/tigervnc-xserver-make.log"
        say_done $?

        doing 'Install'
        cd "${topdir}/unix/vncpasswd"
        make install &> "${dep_logs}/tigervnc-vncpasswd-install.log"
        cd "${topdir}/unix/vncconfig"
        make install &> "${dep_logs}/tigervnc-vncconfig-install.log"
        cd "${topdir}/unix/xserver"
        make install &> "${dep_logs}/tigervnc-xserver-install.log"
        say_done $?
    else
        install_dist tigervnc
    fi
}
