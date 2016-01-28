#==============================================================================
# Copyright (C) 2007-2015 Stephen F. Norledge and Alces Software Ltd.
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
require 'alces/packager/config'
require 'alces/packager/depot'
require 'dm-core'
require 'dm-migrations'

module Alces
  module Packager
    module Dao
      class << self
        def initialize!(opts = {})
          DataMapper.setup(:default, "sqlite::memory:")
          Depot.each do |d|
            DataMapper.setup(d.to_sym, "sqlite://#{File.expand_path(File.join(Config.dbroot(d),'package.db'))}")
          end
        end

        def finalize!
          DataMapper.finalize
          Depot.each do |d|
            begin
              DataMapper::Model.descendants.each {|m| m.send(:auto_upgrade!, d.to_sym)}
            rescue
              nil
            end
          end
        end
      end
    end
    Dao.initialize!
  end
end
