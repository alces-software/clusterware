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
cw_LIBPATH="${cw_LIBPATH:-"${cw_ROOT}"/lib/functions}"

function require() {
    local name dirs dir
    name="$1"
    if [ "${BASH_VERSINFO[0]}" == "4" -a "${BASH_VERSINFO[1]}" == "2" ]; then
        declare -A -g cw_LOADED_LIBS
    elif [ -z "$cw_LOADED_LIBS" ]; then
        cw_LOADED_LIBS="" declare -A cw_LOADED_LIBS
    fi
    if [ -z ${cw_LOADED_LIBS[$name]} ]; then
        IFS=':' read -ra dirs <<< "${cw_LIBPATH}"
        for dir in "${dirs[@]}"; do
            if [ -f "${dir}"/"${name}.functions.sh" ]; then
                source "${dir}"/"${name}.functions.sh"
                cw_LOADED_LIBS[$name]=true
                break
            fi
        done
        if [ -z ${cw_LOADED_LIBS[$name]} ]; then
            echo "Library not found: ${name}"
        fi
    fi
}
export -f require
export cw_ROOT cw_LIBPATH
