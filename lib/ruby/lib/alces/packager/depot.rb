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
require 'alces/packager/io_handler'
require 'alces/tools/file_management'

module Alces
  module Packager
    class Depot
      include Alces::Tools::FileManagement

      class << self
        def find(name)
          # special cases
          return if name == 'depots' || name == 'etc'
          if File.symlink?(File.join(Config.depotroot,name))
            Depot.new(name: name)
          end
        end

        def list
          Dir.glob(File.join(Config.depotroot,'*')).each do |p|
            if File.symlink?(p)
              name = File.basename(p)
              say name
            end
          end
        end
      end

      attr_accessor :source_url, :name, :io, :metadata
      delegate :utter, :say, :warning, :with_spinner, :doing, :title, :tty?, :colored_path, :to => :io

      def initialize(source_url: nil, name: nil)
        self.source_url = source_url
        self.name = name || File.basename(source_url)
        self.io = IoHandler
      end

      def fetch
        if source_url.nil?
          raise DepotError, "No source URL was supplied."
        elsif exists?(name)
          raise DepotError, "Depot already exists: #{name}"
        end
        target = File.expand_path(File.join(Config.archives_dir,'depots',name))
        timeout = (Config.fetch_timeout rescue nil) || 10
        title 'Fetching depot'

        doing 'Metadata'
        mkdir_p(target)
        with_spinner do
          run(['wget',"#{source_url}/metadata.yml",'-T',timeout.to_s,'-t','1','-O',"#{target}/metadata.yml"]) do |r|
            raise DepotError, "Unable to download metadata." unless r.success?
          end
        end
        load_metadata("#{target}/metadata.yml")
        if metadata[:id].nil? || metadata[:name].nil?
          raise DepotError, "Invalid or corrupted depot metadata detected."
        elsif depot_exists?(metadata[:id])
          raise DepotError, "Depot already exists: #{metadata[:name]}:#{metadata[:id]}"
        end
        say 'OK'.color(:green)

        doing 'Content'
        with_spinner do
          run(['wget',"#{source_url}/content.tgz",'-T',timeout.to_s,'-O',"#{target}/content.tgz"]) do |r|
            raise DepotError, "Unable to download content." unless r.success?
          end
        end
        say 'OK'.color(:green)

        doing 'Extract'
        run(['tar',"-zxf","#{target}/content.tgz",'-C',depot_root])
        say 'OK'.color(:green)

        doing 'Link'
        cp("#{target}/metadata.yml", File.join(depot_install_path(metadata[:id]), 'metadata.yml'))
        ln_s(depot_install_path(metadata[:id]), depot_path(name))
        say 'OK'.color(:green)
        true
      end

      def enable
        target = File.join(depot_path(name), '$cw_DIST', 'etc', 'modules')
        if all_modulespaths.include?(target)
          say("#{"WARNING!".color(:yellow)} Depot already enabled: #{name}")
        else
          title "Enabling depot: #{name}"
          doing 'Enable'
          modulespaths do |paths|
            paths.insert(paths.index {|p| p[0] != '#'} || 0, target) if !paths.include?(target)
          end
          puts "module use #{depot_path(name)}/$cw_DIST/etc/modules"
          say 'OK'.color(:green)
        end
      end

      def disable
        target = File.join(depot_path(name), '$cw_DIST', 'etc', 'modules')
        if !all_modulespaths.include?(target)
          say("#{"WARNING!".color(:yellow)} Depot already disabled: #{name}")
        else
          if Process.euid == 0 || user_modulespaths.include?(target)
            title "Disabling depot: #{name}"
            doing 'Disable'
            modulespaths { |paths| paths.reject! {|p| p == target} }
            puts "module unuse #{target}"
            say 'OK'.color(:green)
          else
            raise InvalidSelectionError, "Unable to disable repository in global configuration."
          end
        end
      end

      private
      def global_modulespaths
        f = File.join(ENV['cw_ROOT'], 'etc', 'modulespath')
        paths = File.exist?(f) ? File.read(f).split("\n") : []
      end

      def user_modulespaths
        f = File.join(ENV['HOME'],'.modulespath')
        paths = File.exist?(f) ? File.read(f).split("\n") : []
      end

      def all_modulespaths
        global_modulespaths + user_modulespaths
      end

      def modulespaths(&block)
        f = if Process.euid == 0
              File.join(ENV['cw_ROOT'], 'etc', 'modulespath')
            else
              File.join(ENV['HOME'],'.modulespath')
            end
        paths = File.exist?(f) ? File.read(f).split("\n") : []
        if block.call(paths)
          File.write(f, paths.join("\n"))
        end
      end

      def exists?(name)
        File.exist?(depot_path(name))
      end

      def depot_exists?(id)
        File.exist?(depot_install_path(id))
      end

      def depot_path(name)
        File.join(Config.depotroot,name)
      end

      def depot_root
        File.join(Config.depotroot,'depots')
      end

      def depot_install_path(identifier)
        File.join(depot_root,identifier.to_s)
      end

      def load_metadata(f)
        self.metadata = (YAML.load_file(f) rescue {})
      end
    end
  end
end
