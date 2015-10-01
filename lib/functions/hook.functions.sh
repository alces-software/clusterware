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
cw_HANDLER_PLUGINDIR="${cw_ROOT}/etc/handlers"
export PLUGIN_PATH="$cw_HANDLER_PLUGINDIR"
cw_HOOK_RUNNER="${cw_ROOT}/opt/pluginhook/bin/pluginhook"
cw_HANDLER_REPODIR="${cw_ROOT}/var/lib/handler/repos"
cw_HANDLER_DEFAULT_REPO="base"
cw_HANDLER_DEFAULT_REPO_URL="${cw_HANDLER_DEFAULT_REPO_URL:-https://:@github.com/alces-software/clusterware-handlers}"

hook_run() {
    local event
    event=$1
    shift
    "$cw_HOOK_RUNNER" $event "$@"
}

handler_is_enabled() {
    local handler
    handler="$1"
    [ -e "${cw_HANDLER_PLUGINDIR}/${handler}" ]
}

handler_repo_exists() {
    [ -d "${cw_HANDLER_REPODIR}/${repo}" ]
}

handler_exists() {
    [ -d "${cw_HANDLER_REPODIR}/${repo}/${handler}" ]
}

handler_enable() {
    local handler
    handler="$1"
    ln -s "${cw_HANDLER_REPODIR}/${handler}" "${cw_HANDLER_PLUGINDIR}/$(basename ${handler})"
}

handler_disable() {
    local handler
    handler="$1"
    [ -L "${cw_HANDLER_PLUGINDIR}/${handler}" ] &&
        rm -f "${cw_HANDLER_PLUGINDIR}/${handler}"
}
