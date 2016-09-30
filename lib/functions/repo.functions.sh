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
    [ -e "${plugindir}/${plugin}" -o -e "${plugindir}"/*-"${plugin}" ]
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

repo_plugin_install() {
    local repodir plugin distro installer exitcode
    repodir="$1"
    plugin="$2"
    distro="$3"
    shift 3
    if [ -f "${repodir}/${plugin}/metadata.yml" ]; then
        installer="$(mktemp /tmp/clusterware-installer.XXXXXXXX.sh)"
        repo_generate_script "${repodir}/${plugin}" "${installer}" "${distro}" "install"
        cd "${cw_ROOT}"
        set -o pipefail
        /bin/bash "${installer}" "$@" 2>&1 | sed 's/^/  >>> /g'
        exitcode=$?
        set +o pipefail
        rm -f "${installer}"
        return $exitcode
    fi
}

repo_plugin_enable() {
    local repodir plugindir plugin
    repodir="$1"
    plugindir="$2"
    plugin="$3"
    ln -s "${repodir}/${plugin}" "${plugindir}/$(repo_order_prefix "${repodir}/${plugin}")$(basename ${plugin})"
}

repo_plugin_disable() {
    local plugindir plugin
    plugindir="$1"
    plugin="$2"
    [ -L "${plugindir}/${plugin}" ] &&
        rm -f "${plugindir}/${plugin}"
}

repo_generate_script() {
    local metadata_path script distro key
    metadata_path="$1"
    script="$2"
    distro="$3"
    key="$4"
    ruby_run <<RUBY
require 'yaml'

config = YAML.load_file('${metadata_path}/metadata.yml')
installer = "set -e"
installer = ". /etc/profile.d/alces-clusterware.sh"
installer << "\n" << 'cw_ROOT=${cw_ROOT}'
installer << "\n" << 'cd ${metadata_path}'
if config.key?('${key}')
  install_meta = config['${key}']
  installer << "\n" << (config['${key}']['${distro}'] || '')
  installer << "\n" << (config['${key}']['_'] || '')
end
File.write('${script}', installer)
RUBY
}

repo_has_script() {
    local metadata_path key
    metadata_path="$1"
    key="$2"
    ruby_run <<RUBY
require 'yaml'
config = YAML.load_file('${metadata_path}/metadata.yml')
exit(1) unless config.key?('${key}')
RUBY
}

repo_list_scripts() {
    local metadata_path key
    metadata_path="$1"
    ruby_run <<RUBY
require 'yaml'
config = YAML.load_file('${metadata_path}/metadata.yml')
puts config.keys.join(' ')
RUBY
}

repo_order_prefix() {
    local metadata_path
    metadata_path="$1"
    if [ -f "${metadata_path}/metadata.yml" ]; then
        ruby_run <<EOF
require 'yaml'
config = YAML.load_file('${metadata_path}/metadata.yml')
puts "#{config['order']}-" if config['order']
EOF
    fi
}
