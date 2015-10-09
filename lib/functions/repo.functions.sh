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

repo_plugin_is_enabled() {
    local plugin plugindir
    plugindir="$1"
    plugin="$2"
    [ -e "${plugindir}/${plugin}" ]
}

repo_exists() {
    local dir repo
    dir="$1"
    repo="$2"
    [ -d "${dir}/${repo}" ]
}

repo_plugin_exists() {
    local repodir repo plugin
    repodir="$1"
    repo="$2"
    plugin="$3"
    [ -d "${repodir}/${repo}/${plugin}" ]
}

repo_plugin_preinstall() {
    local repodir plugin distro preinstall
    repodir="$1"
    plugin="$2"
    distro="$3"
    if [ -f "${repodir}/${plugin}/metadata.yml" ]; then
        preinstall="$(mktemp /tmp/clusterware-preinstall.XXXXXXXX.sh)"
        ruby_run <<RUBY
require 'yaml'

config = YAML.load_file('${repodir}/${plugin}/metadata.yml')
preinstall = ""
if config.key?('preinstall')
  preinstall << (config['preinstall']['${cw_DIST}'] || '')
  preinstall << "\n" << (config['preinstall']['_'] || '')
end
File.write('${preinstall}', preinstall)
RUBY
        cd "${cw_ROOT}"
        /bin/bash "${preinstall}"
        rm -f "${preinstall}"
    fi
}

repo_plugin_enable() {
    local repodir plugindir plugin
    repodir="$1"
    plugindir="$2"
    plugin="$3"
    ln -s "${repodir}/${plugin}" "${plugindir}/$(basename ${plugin})"
}

repo_plugin_disable() {
    local plugindir plugin
    plugindir="$1"
    plugin="$2"
    [ -L "${plugindir}/${plugin}" ] &&
        rm -f "${plugindir}/${plugin}"
}
