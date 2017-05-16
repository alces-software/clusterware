#!/bin/bash
#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
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

_dropcache_clear_cache() {
    local cache_int="$1"
    shift

    echo "$cache_int" > /proc/sys/vm/drop_caches
}

dropcache_cli_input() {
    local input="$1"
    shift

    case "$input" in
        "")
            $cw_ROOT/bin/alces configure help dropcache
            ;;
        1|p|pa|pag|page|pagec|pageca|pagecac|pagecac|pagecach|pagecache)
            _dropcache_clear_cache 1
            ;;
        2|s|sl|sla|slab|slabo|slabob|slabobj|slabobjs)
            _dropcache_clear_cache 2
            ;;
        3|b|bo|bot|both)
            _dropcache_clear_cache 3
            ;;
        *)
            action_die "unrecognised option: $input"
    esac
}