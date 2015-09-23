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
alces_RUBYHOME="${target}/opt/ruby"
alces_RUBY="${target}/opt/ruby/bin/ruby"

detect_ruby() {
    [ -d "${target}/opt/ruby" ]
}

fetch_ruby() {
    title "Fetching Ruby"
    if [ "$dep_source" == "fresh" ]; then
        fetch_source https://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.3.tar.gz ruby-source.tar.gz
    else
        fetch_dist ruby
    fi
}

install_ruby() {
    title "Installing Ruby"
    if [ "$dep_source" == "fresh" ]; then
        doing 'Extract'
        tar -C "${dep_build}" -xzf "${dep_src}/ruby-source.tar.gz"
        say_done $?

        cd "${dep_build}"/ruby-*

        doing 'Configure'
        ./configure --prefix="${alces_RUBYHOME}" --enable-shared --disable-install-doc \
            --with-libyaml --with-opt-dir="${target}/opt/lib" \
            &> "${dep_logs}/ruby-configure.log"
        say_done $?

        doing 'Compile'
        make &> "${dep_logs}/ruby-make.log"
        say_done $?

        doing 'Install'
        make install &> "${dep_logs}/ruby-install.log"
        say_done $?
    else
        install_dist ruby
    fi
}
