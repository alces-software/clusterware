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
    apt-get install -y openssl libssl1.0.0 libreadline6 zlib1g libffi6 libgmp10 && \
        apt-get install -y man-db && \
        apt-get install -y dnsutils && \
        apt-get install -y uuid
}

install_base_prerequisites() {
    apt-get install -y lsof gcc unzip curl sudo
}

install_build_prerequisites() {
    # git (and possibly others)
    # ruby
    # pluginhook
    apt-get install -y build-essential && \
        apt-get install -y libcurl4-openssl-dev libexpat1-dev tcl gettext && \
        apt-get install -y libreadline-dev zlib1g-dev libssl-dev libffi-dev && \
        apt-get install -y git golang
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
