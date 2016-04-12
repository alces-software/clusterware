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
require 'alces/packager/config'
require 'alces/packager/io_handler'
require 'alces/tools/file_management'

module Alces
  module Packager
    class Depot
      include Alces::Tools::FileManagement
      include Alces::Tools::Logging

      class << self
        def hash_path_for(name)
          depot_path = File.join(Config.depotroot,name)
          if File.symlink?(depot_path)
            File.readlink(depot_path)
          else
            nil
          end
        end

        def find(name)
          # special cases
          return if name == 'depots' || name == 'etc'
          if File.symlink?(File.join(Config.depotroot,name))
            Depot.new(name)
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

        def each(&block)
          Dir.glob(File.join(Config.depotroot,'*'))
            .select { |p| File.symlink?(p) }
            .map { |p| File.basename(p) }
            .each(&block)
        end
      end

      attr_accessor :name
      delegate :confirm, :say, :with_spinner, :doing, :title, :to => IoHandler

      def initialize(name)
        self.name = name
      end

      def enable
        if enabled?
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
        notify_depot(name,'enabled')
      end

      def disable
        if !enabled?
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
        notify_depot(name,'disabled')
      end

      def enabled?
        all_modulespaths.include?(target)
      end

      def init(disabled = false)
        title "Initializing depot: #{name}"
        doing "Initialize"
        with_spinner do
          run([ENV["cw_ROOT"],'bin','alces'].join('/'),'gridware','init',Config.depotroot,name) do |res|
            unless res.success?
              raise DepotError, "Unable to initialize depot."
            end
          end
        end
        say 'OK'.color(:green)
        if disabled
          disable
        else
          puts "module use #{depot_path(name)}/$cw_DIST/etc/modules"
        end
      end

      def purge
        say "Purging depot: #{name.color(:magenta).bold}"
        files = [Depot.hash_path_for(name), depot_path(name)]
        msg = <<EOF
Purge operation will remove the following files/directories:
  #{files.join("\n  ")}
EOF
        return false unless confirm(msg)
        disable if enabled?
        title "Removing depot"
        doing "Purge"
        with_spinner do
          files.each(&method(:rm_r))
        end
        say 'OK'.color(:green)
      end

      private
      def notify_depot(name, state)
        if ENV['cw_GRIDWARE_notify'] == 'true'
          id = File.basename(File.readlink(depot_path(name)))
          run(File.join(ENV['cw_ROOT'],'libexec','share','trigger-event'),
              '--local','nfs-export',depot_install_path(id)) do |r|
            raise DepotError, "Unable to trigger depot event." unless r.success?
          end
          run(File.join(ENV['cw_ROOT'],'libexec','share','trigger-event'),
              'gridware-depots',
              "#{id}:#{name}:#{state}") do |r|
            raise DepotError, "Unable to trigger depot event." unless r.success?
          end
        end
      end

      def target
        @target ||= File.join(depot_path(name), '$cw_DIST', 'etc', 'modules')
      end

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

      def depot_path(name)
        File.join(Config.depotroot,name)
      end

      def depot_root
        File.join(Config.depotroot,'depots')
      end

      def depot_install_path(identifier)
        File.join(depot_root,identifier.to_s)
      end
    end
  end
end
