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
detect_bundler() {
    [ -f "${target}/opt/ruby/bin/bundle" ]
}

fetch_bundler() {
    if fetch_handling_is_source; then
        title "Fetching Bundler"
        fetch_source https://rubygems.org/downloads/bundler-1.10.6.gem bundler.gem
    fi
}

install_bundler() {
    title "Installing Bundler"
    doing 'Install'
    "${target}/opt/ruby/bin/gem" install --local "${dep_src}/bundler.gem" &> "${dep_logs}/bundler-install.log"
    say_done $?
}
