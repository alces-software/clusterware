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
.PHONY: develop test_bash test_ruby test all
SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

develop:
	(source $(SELF_DIR)/../etc/distro.rc && cw_BUILD_source_dir=/media/host/clusterware /media/host/clusterware/scripts/develop)

test_bash:
	bats $(SELF_DIR)/../../**/__tests__/

test_ruby:
	(cd $(SELF_DIR)/../lib/ruby && $(SELF_DIR)/../opt/ruby/bin/rake test)

test: test_bash test_ruby

all: test
