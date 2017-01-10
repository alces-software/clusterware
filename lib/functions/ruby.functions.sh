#==============================================================================
# Copyright (C) 2015-2016 Stephen F. Norledge and Alces Software Ltd.
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
    . "${cw_ROOT}"/etc/ruby.rc
    export PATH LD_LIBRARY_PATH
    ${cw_ROOT}/opt/ruby/bin/ruby -se 'eval ARGF.read'
}

ruby_bundle_exec() {
    . "${cw_ROOT}"/etc/ruby.rc
    export PATH LD_LIBRARY_PATH
    (
        # TODO - this is a temporary fix to ensure that `alces howto`
        # works in Flight Compute 2016.4r1.  It should be fixed
        # properly in Clusterware 1.8.0.
        cd "${cw_ROOT}"/opt/gridware
        ${cw_ROOT}/opt/ruby/bin/bundle exec "$@"
    )
}

ruby_exec() {
    . "${cw_ROOT}"/etc/ruby.rc
    export PATH LD_LIBRARY_PATH
    ${cw_ROOT}/opt/ruby/bin/ruby "$@"
}
