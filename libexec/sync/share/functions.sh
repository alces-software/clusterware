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
_target_for() {
    local config_file
    config_file="$1"
    ruby_run <<RUBY
require 'yaml'
config = (YAML.load_file("${config_file}") rescue nil) || {}
if config[:source] == :home
  puts "$HOME"
else
  puts config[:source]
end
RUBY
}

_get_password() {
    local prompt password
    prompt="$1"
    while [ -z "${password}" ]; do
        read -p " ${prompt}: " -s password
        echo "" 1>&2
    done
    echo "${password}"
}

_int_handler() {
    _INTERRUPTED=true
    stty echo
    echo "Skipping."
}
