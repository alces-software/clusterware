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
require 'memoist'

module Alces
  module Packager
    module ParameterUtils
      extend Memoist

      def print_params_help(defn)
        if defn.metadata[:params] && defn.metadata[:params].any?
          say "\n  #{'Required parameters'.underline} (param=value)\n\n"
          defn.params.each do |k,v|
            if default_params(defn)[k]
              default = " [default: #{default_params(defn)[k]}]"
            else
              default = ""
            end
            say sprintf("%15s: %s%s\n", k, v, default)
          end
        end
      end

      def default_params(pkg)
        # load defaults file
        pkg_version = "#{pkg.type}/#{pkg.name}/#{pkg.version}"
        pkg_name = "#{pkg.type}/#{pkg.name}"
        pkg_defaults = package_defaults[pkg_version] || package_defaults[pkg_name] || {}
        # return default parameters for the pkg
        {}.merge(pkg.metadata[:param_defaults] || {}).merge(pkg_defaults)
      end
      memoize :default_params

      def package_defaults
        @package_defaults ||= {}.tap do |h|
          cfgfile = Alces::Tools::Config.find("params", false)
          h.merge!(YAML.load_file(cfgfile)) unless cfgfile.nil?
        end
      end
    end
  end
end
