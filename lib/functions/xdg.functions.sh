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
xdg_cache_home() {
    echo "${XDG_CACHE_HOME:-$HOME/.cache}"
}

xdg_config_home() {
    echo "${XDG_CONFIG_HOME:-$HOME/.config}"
}

xdg_config_dirs() {
    echo "${XDG_CONFIG_DIRS:-/etc/xdg}"
}

xdg_config_search() {
    xdg_search "$(xdg_config_home):$(xdg_config_dirs)" "$@"
}

xdg_data_home() {
    echo "${XDG_DATA_HOME:-$HOME/.local/share}"
}

xdg_data_dirs() {
    echo "${XDG_DATA_DIRS:-/usr/local/share/:/usr/share/}"
}

xdg_data_search() {
    xdg_search "$(xdg_data_home):$(xdg_data_dirs)" "$@"
}

xdg_search() {
    local haystack_paths xdg_dirs
    haystack_paths="$1"
    needle="$2"
    fn="$3"
    shift
    IFS=: read -a xdg_dirs <<< "${haystack_paths}"
    xdg_find_needle "$needle" "$fn" "${xdg_dirs[@]}"
}

xdg_find_needle() {
    local a needle fn
    needle="$1"
    fn="$2"
    shift 2
    for a in "$@"; do
        if [ -e "${a}"/"${needle}" ]; then
            if [ "$fn" ]; then
                $fn "${a}"/"${needle}"
            else
                echo "${a}"/"${needle}"
            fi
            return 0
        fi
    done
    return 1
}
