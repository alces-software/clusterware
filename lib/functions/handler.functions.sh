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
require ruby
require repo
require log

cw_HANDLER_PLUGINDIR="${cw_ROOT}/etc/handlers"
export PLUGIN_PATH="$cw_HANDLER_PLUGINDIR"
cw_HANDLER_HOOK_RUNNER="${cw_ROOT}/opt/pluginhook/bin/pluginhook"
cw_HANDLER_REPODIR="${cw_ROOT}/var/lib/handler/repos"
cw_HANDLER_DEFAULT_REPO="base"
cw_HANDLER_DEFAULT_REPO_URL="${cw_HANDLER_DEFAULT_REPO_URL:-https://:@github.com/alces-software/clusterware-handlers}"
cw_HANDLER_BROADCASTER="${cw_ROOT}/opt/serf/bin/serf"
cw_HANDLER_name="$(cd "$(dirname "$0")" && basename "$(pwd)"):$(basename "$0")"

handler_run_hook() {
    local event
    event="$1"
    shift
    "$cw_HANDLER_HOOK_RUNNER" "$event" "$@"
}

handler_is_enabled() {
    repo_plugin_is_enabled "${cw_HANDLER_PLUGINDIR}" "$@"
}

handler_repo_exists() {
    repo_exists "${cw_HANDLER_REPODIR}" "$@"
}

handler_exists() {
    repo_plugin_exists "${cw_HANDLER_REPODIR}" "$@"
}

handler_install() {
    repo_plugin_install "${cw_HANDLER_REPODIR}" "$@"
}

handler_enable() {
    repo_plugin_enable "${cw_HANDLER_REPODIR}" "${cw_HANDLER_PLUGINDIR}" "$@"
}

handler_disable() {
    repo_plugin_disable "${cw_HANDLER_PLUGINDIR}" "$@"
}

handler_broadcast() {
    local event
    event="$1"
    "${cw_HANDLER_BROADCASTER}" event -coalesce=false "${event}" "$*"
}

handler_tee() {
    local input
    read input
    "$@" <<< "${input}" 2>&1 | log_blob "${cw_LOG_default_log}" "${cw_HANDLER_name}"
    echo -n "${input}"
}
