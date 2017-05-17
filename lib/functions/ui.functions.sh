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
require process

_ui_spinner_kill() {
  if [ "$spin_pid" ]; then
    kill $spin_pid 2>/dev/null
    echo
  fi
}

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
            process_trap_add INT _ui_spinner_kill
            if ! process_trap_get_exit INT >/dev/null; then
              process_trap_set_exit INT 1
            fi
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
    if [ -z "$cw_UI_disable_spinner" ]; then
	toggle_spin
    fi
}

say_done () {
    if [ -z "$cw_UI_disable_spinner" ]; then
	toggle_spin
    fi
    if [ $1 -gt 0 ]; then
        echo '[31mFAIL[0m'
        action_exit 1
    else
        echo '[32mOK[0m '
    fi
}

ui_print_enabled_status_line() {
    local enabled repo item sub_item sub_item_section
    enabled="${1}"
    repo="${2}"
    item="${3}"
    sub_item="${4}"

    if [[ -n "${sub_item}" ]]; then
        sub_item_section="/\e[38;5;${cw_THEME_mid}m${sub_item}\e[0m"
    fi
    echo -e "[${enabled}] \e[38;5;${cw_THEME_sec1}m${repo}\e[0m/\e[38;5;${cw_THEME_sec2}m${item}\e[0m${sub_item_section}"
}
