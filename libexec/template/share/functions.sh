#==============================================================================
# Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
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
require files

_template_render() {
    local vars template
    template="$1"
    vars=$(grep '^#@ ' "${template}" | cut -c4-)
    if [ "$vars" ]; then
        declare -A cw_TEMPLATE
        eval "$vars"
    fi
    files_load_config --optional gridware
    grep -v '^#@ ' "${template}" |
        sed -e "s,_GRIDWARE_,${cw_GRIDWARE_root:-/opt/gridware},g" \
            -e "s,_DATADIR_,${cw_TEMPLATE[datadir]:-$(basename "${template}" .sh.tpl)},g" \
            -e "s/_TEMPLATE_/$(basename "${template}" .sh.tpl)/g"
}
