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
require 'yaml'
require 'alces/tools/config'
module Alces
  module Packager
    module Config
      DEFAULT_CONFIG = {
        buildroot: '/usr/src/alces',
        gridware: '/opt/gridware',
        depotroot: '/opt/gridware',
        use_default_params: false
      }

      class << self
        def config
          @config ||= DEFAULT_CONFIG.dup.tap do |h|
            cfgfile = Alces::Tools::Config.find("gridware", false)
            h.merge!(YAML.load_file(cfgfile)) unless cfgfile.nil?
          end
        end

        def packages_dir(depot)
          File.expand_path(File.join(depot_path(depot),'pkg'))
        end

        def modules_dir(depot)
          File.expand_path(File.join(depot_path(depot),'etc/modules'))
        end

        def dependencies_dir(depot)
          File.expand_path(File.join(depot_path(depot),'etc/depends'))
        end

        def dbroot(depot)
          File.expand_path(File.join(depot_path(depot),'etc'))
        end

        def method_missing(s,*a,&b)
          if config.has_key?(s)
            config[s]
          else
            super
          end
        end

        private
        def depot_path(depot)
          File.join(Depot.hash_path_for(depot),ENV['cw_DIST'] || 'unknown')
        end
      end
    end
  end
end
