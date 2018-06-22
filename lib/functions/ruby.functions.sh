#==============================================================================
# Copyright (C) 2015-2017 Stephen F. Norledge and Alces Software Ltd.
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
ruby_run() {
    ruby -se 'eval ARGF.read'
}

ruby_bundle_exec() {
  local bundle_dir
  bundle_dir="$1"
  if [ "${bundle_dir}" ]; then
      shift
  else
    bundle_dir="${cw_ROOT}/lib/ruby"
  fi
  (
    cd "${bundle_dir}"
    bundle exec "$@"
  )
}

ruby_exec() {
    ruby "$@"
}
