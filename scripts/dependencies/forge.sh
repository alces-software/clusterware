#==============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd.
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
cw_FORGE_HOME="${target}/opt/forge"

detect_forge() {
  [ -d "${cw_FORGE_HOME}" ]
}

fetch_forge() {
  title "Fetching Forge"
  fetch_dist forge
}

install_forge() {
  title "Installing Forge"
  install_dist forge

  pushd "${cw_FORGE_HOME}" > /dev/null
  cp -r dist/* ${target}
  popd > /dev/null
}
