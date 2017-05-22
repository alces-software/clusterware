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
process_wait_for_pid() {
    local pid
    pid=$1
    while [ -d /proc/$pid ]; do
        sleep 5 &
        # Wait for the backgrounded sleep to complete. Running the sleep in the
        # background, allows this process to be responsive to any signals it
        # receives.
        wait $!
    done
}

process_reexec_sudo() {
    local sudo_args
    if [ "$UID" != "0" ]; then
        sudo_args=()
        process_reexec_with_sudo "$@"
    fi
}

process_reexec_su() {
    local uname sudo_args
    uname="$1"
    shift
    if [ "$UID" != "$(id -u ${uname})" ]; then
        sudo_args=(-u ${uname})
        process_reexec_with_sudo "$@"
    fi
}

process_reexec_sg() {
    local gname sudo_args
    gname="$1"
    shift
    gid=$(getent group $gname | cut -d: -f3 2>/dev/null)
    if [ -z "$gid" ]; then
        return 1
    elif ! id -G | grep -q "\b$gid\b"; then
        sudo_args=(-g ${gname})
        process_reexec_with_sudo "$@"
    fi
}

process_reexec_with_sudo() {
    local cmd
    if [ "$1" == "--plain" ]; then
        shift
        cmd_args=("$0" "$@")
    else
        cmd_args=(-E /bin/bash -c "$(declare -f require); export -f require; exec /bin/bash \"\$0\" \"\$@\"" "$0" "$@")
    fi
    cw_BINNAME="${cw_BINNAME% *}"
    exec sudo "${sudo_args[@]}" "${cmd_args[@]}"
}

process_run() {
    local name bin
    name="$1"
    shift
    bin=$(type -P ${name})
    if [ "${bin}" ]; then
        ${bin} "$@"
    fi
}

process_sh() {
    local script
    script="$1"
    shift
    if [ -f "${script}" ]; then
        /bin/bash ${script} "$@"
    fi
}

process_trap_handle() {
  local signal trap_list_var trap_exit_var
  signal=$1
  trap_list_var="_PROCESS_${signal}"
  trap_exit_var="_PROCESS_EXIT_${signal}"
  ${!trap_list_var}
  if [ ${!trap_exit_var} -a ${!trap_exit_var} != "false" ]; then
    exit ${!trap_exit_var}
  fi
}

process_trap_add() {
  local signal=$1 fn=$2 trap_list_var

  trap_list_var="_PROCESS_${signal}"
  printf -v "$trap_list_var" "${!trap_list_var}$fn ; "
  trap "process_trap_handle $signal" $signal
}

# By default the trap does not exit
# An exit_code of 'false' explicitly prevents the trap exiting
process_trap_set_exit() { 
  local force signal exit_code trap_exit_var
  if [[ "$1" == "--force" ]]; then
    force="true"
    shift
  fi
  signal="$1"
  if [[ -z "$2" ]]; then
    exit_code=1
  else
    exit_code="$2"
  fi

  trap_exit_var="_PROCESS_EXIT_${signal}"
  if [[ -n "${!trap_exit_var}" && -z "$force" ]]; then
    return 1
  fi

  printf -v "$trap_exit_var" "$exit_code"
  trap "process_trap_handle $signal" $signal   
}

process_trap_get_exit() {
  local signal=$1 trap_exit_var

  trap_exit_var="_PROCESS_EXIT_$signal"
  if [ ${!trap_exit_var} ]; then
    echo ${!trap_exit_var}
    return 0
  else
    return 1
  fi
}
