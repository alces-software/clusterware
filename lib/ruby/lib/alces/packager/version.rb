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
require 'alces/tools/file_management'
require 'alces/packager/dao'

module Alces
  module Packager
    class Version
      class << self
        include Alces::Tools::FileManagement

        def write_defaults!(depot)
          Version.all(default: true).each do |v|
            versionfile_name = File.join(Config.modules_dir(depot), v.path, '.version')
#            raise ModulefileError, "Failed to write module file #{versionfile_name} (already exists)" if File.exists?(versionfile_name)
            if File.directory?(File.dirname(versionfile_name))
              raise ModulefileError, "Failed to write module file #{versionfile_name}" unless write(versionfile_name, ModuleTree.versionfile_for(v.version))
            else
              IoHandler.warning("No directory found for #{v.path}; please purge #{v.path}")
            end
          end
        end
      end

      include DataMapper::Resource

      property :id, Serial
      property :path, String
      property :version, String
      property :default, Boolean

      before :save do
        self.default = (comparable_versions.empty? ||
                        (comparable_versions.length == 1 && comparable_versions.first.id == self.id))
      end

      after :destroy do
        comparable_versions.update(default: true) if comparable_versions.length == 1
      end

      private
      def comparable_versions
        @comparable_versions = Version.all(path: path)
      end
    end
    Dao.finalize!
  end
end
