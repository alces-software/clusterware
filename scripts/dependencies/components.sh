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
detect_components() {
    [ -d "${target}/lib/ruby/.bundle" ]
}

fetch_components() {
    if ! fetch_handling_is_source; then
        title "Fetching Ruby components"
        fetch_dist 'components'
    fi
}

install_components() {
    title "Installing Ruby components"
    if fetch_handling_is_source; then
        cd "${target}/lib/ruby"
        rm -rf vendor/ruby
        doing 'Configure'
	# XXX - path into opt/clusterware-bundle or something to allow
	# for easier dev separation...? .bundle file probably still
	# awkward tho... perhaps dev operation copies .bundle and
	# vendor/ruby into dev tree...
        "${cw_RUBYHOME}/bin/bundle" install \
            --local \
            --without test \
            --path=vendor \
            &> "${dep_logs}/components-install.log"
        say_done $?
    else
        install_dist 'components'
    fi
}
