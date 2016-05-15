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
deps="git libyaml ruby bundler modules genders pdsh components tigervnc xwd serf pluginhook websockify jq jo"
serviceware="gridscheduler aws s3cmd galaxy simp_le alces-storage-manager-daemon clusterware-dropbox-cli"
dists="el6 el7"
dist_url=${cw_BUILD_dist_url:-https://s3-eu-west-1.amazonaws.com/packages.alces-software.com/clusterware/dist}
target=${cw_BUILD_target_dir:-/opt/clusterware}
