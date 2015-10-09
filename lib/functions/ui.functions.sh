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
require action

toggle_spin() {
        if [ -z "$spin_pid" ]; then
            (
                i=1
                sp="/-\|"
                printf " "
                while true;
                do
                    printf "\b[1m${sp:i++%${#sp}:1}[0m"
                    if [[ i -eq ${#sp} ]]; then
                        i=0
                    fi
                    sleep 0.2
                done
            ) &
            spin_pid=$!
        else
            sleep 1
            kill $spin_pid
            wait $spin_pid 2>/dev/null
            printf "\b"
            unset spin_pid
        fi
}

title() {
    printf "\n > $1\n"
}

doing() {
    if [ -z "$2" ]; then
        pad=12
    else
        pad=$2
    fi
    printf "    [36m%${pad}s[0m ... " "$1"
    toggle_spin
}

say_done () {
    toggle_spin
    if [ $1 -gt 0 ]; then
        echo '[31mFAIL[0m'
        action_exit 1
    else
        echo '[32mOK[0m '
    fi
}
