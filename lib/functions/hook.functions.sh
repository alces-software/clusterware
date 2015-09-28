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
HANDLER_PLUGINDIR="${alces_BASE}/etc/handlers"
export PLUGIN_PATH="$HANDLER_PLUGINDIR"
HOOK_RUNNER="${alces_BASE}/opt/pluginhook/bin/pluginhook"
HANDLER_REPODIR="${alces_BASE}/var/lib/handler/repos"
HANDLER_DEFAULT_REPO="base"
HANDLER_DEFAULT_REPO_URL="${HANDLER_DEFAULT_REPO_URL:-https://:@github.com/alces-software/clusterware-handlers}"

hook_run() {
    local event
    event=$1
    shift
    "$HOOK_RUNNER" $event "$@"
}

handler_is_enabled() {
    local handler
    handler="$1"
    [ -e "${HANDLER_PLUGINDIR}/${handler}" ]
}

handler_repo_exists() {
    [ -d "${HANDLER_REPODIR}/${repo}" ]
}

handler_exists() {
    [ -d "${HANDLER_REPODIR}/${repo}/${handler}" ]
}

handler_enable() {
    local handler
    handler="$1"
    ln -s "${HANDLER_REPODIR}/${handler}" "${HANDLER_PLUGINDIR}/$(basename ${handler})"
}

handler_disable() {
    local handler
    handler="$1"
    [ -L "${HANDLER_PLUGINDIR}/${handler}" ] &&
        rm -f "${HANDLER_PLUGINDIR}/${handler}"
}
