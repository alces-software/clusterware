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
module Alces
  module Packager
    class DepotMetadata
      attr_accessor :name, :metadata

      def initialize(name, metadata)
        self.name = name
        self.metadata = metadata
      end

      def method_missing(s,*a,&b)
        if metadata.has_key?(s)
          metadata[s]
        else
          super
        end
      end

      def region_aware_root
        if metadata[:region_map] && region
          metadata[:region_map][region] || metadata[:region_map].values.first
        elsif metadata[:root] == 'https://s3-eu-west-1.amazonaws.com/packages.alces-software.com/gridware/%24dist' ||
              metadata[:region_map].nil? && metadata[:root].nil?
          Config.default_binary_url
        else
          metadata[:root] || metadata[:region_map].values.first
        end
      end

      private
      def region
        if File.exists?("#{ENV['cw_ROOT']}/etc/config/cluster/instance-aws.rc")
          @region ||= `bash -c 'source #{ENV['cw_ROOT']}/etc/config/cluster/instance-aws.rc 2> /dev/null && echo ${cw_INSTANCE_aws_region}'`.chomp
        end
      end
    end
  end
end
