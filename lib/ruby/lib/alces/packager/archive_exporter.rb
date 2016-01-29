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
require 'alces/tools/execution'
require 'alces/packager/package'
require 'alces/packager/errors'

module Alces
  module Packager
    class ArchiveExporter
      class << self
        def export(*a, &b)
          new(*a, &b).export
        end
      end

      include Alces::Tools::Execution

      attr_accessor :package_path, :depot, :io, :ignore_bad_package
      delegate :say, :with_spinner, :doing, :title, :colored_path, :to => :io
      
      def initialize(package_path, depot, io, ignore_bad_package)
        self.package_path = package_path
        self.depot = depot
        self.io = io
        self.ignore_bad_package = ignore_bad_package
        setup
      end

      def export
        say "Exporting #{colored_path(normalized_package_path)}"
        # copy package and module file from depot root into temporary directory
        Dir.mktmpdir do |dir|
          h = {
            distro: ENV['cw_DIST'],
            type: @type,
            name: @name,
            version: version,
            taggings: []
          }
          
          dest_pkg_dir = File.join(dir, ENV['cw_DIST'], 'pkg', normalized_package_path)
          dest_module_dir = File.join(dir, ENV['cw_DIST'], 'etc', 'modules', normalized_package_path)
          FileUtils.mkdir_p(dest_pkg_dir)
          FileUtils.mkdir_p(dest_module_dir)

          @tags.each do |tag|
            title "Export (#{tag})"
            fqpn = File.join(normalized_package_path, tag)
            module_file = File.join(Config.modules_dir(depot), fqpn)
            pkg_dir = File.join(package_dir, fqpn)
            
            doing "Prepare"
            with_spinner do
              FileUtils.cp_r(pkg_dir, dest_pkg_dir)
              FileUtils.cp_r(module_file, dest_module_dir)
            end
            say 'OK'.color(:green)

            doing "Ready"
            with_spinner do
              # modify depot in modulefiles
              p = Package.first(name: @name, type: @type, version: version, tag: tag)
              h[:taggings] << {
                tag: tag,
                compiler_tag: p.compiler_tag
              }
              s = File.read(File.join(dest_module_dir,tag)).gsub(depot_path,'_DEPOT_')
              File.write(File.join(dest_module_dir,tag),s)
            end
            # warn about depot specifics in package code
            run(['grep','-lr',depot_path,File.join(dest_pkg_dir,tag)]) do |r|
              if r.success?
                files = r.stdout.chomp.gsub(File.join(dest_pkg_dir,tag,''),'').tr("\n",', ')
                if ignore_bad_package
                  say "#{'WARNING!'.color(:yellow)} Package contains hard-coded directory (#{files})"
                else
                  raise PackageError, "Package contains hard-coded directory (#{files})"
                end
              else
                say 'OK'.color(:green)
              end
            end
          end
          File.write(File.join(dir,'metadata.yml'), h.to_yaml)

          title 'Creating archive'
          # tar up temporary tree
          doing 'Archive'
          package_name = normalized_package_path.tr('/','-')
          tar_name = '/tmp/' + package_name + '-' + ENV['cw_DIST'] + '.tar.gz'
          with_spinner do
            run(['tar', '-czf', tar_name, '-C', dir, ENV['cw_DIST'], 'metadata.yml']) do |r|
              raise PackageError, "Unable to create tarball." unless r.success?
            end
          end
          say "#{'OK'.color(:green)}"
          say "\nExported #{colored_path(normalized_package_path)} to #{tar_name}\n\n"
        end
      end
      
      private
      def setup
        @type, @name, @version, tag = package_path.split('/')
        @tags =
          if tag && File.directory?(File.join(package_dir, @type, @name, version, tag))
            @tags = [tag]
          else
            Dir.glob(File.join(package_dir, @type, @name, version, '*'))
              .map(&File.method(:basename))
          end
        if @tags.empty?
          raise NotFoundError, "No package found: #{package_path}"
        end
      end
      
      def package_dir
        @package_dir ||= Config.packages_dir(depot)
      end

      def version
        return @version unless @version.nil?
        if @version.nil?
          candidates = Dir.glob(File.join(package_dir, @type, @name, '*'))
          if candidates.length == 1
            @version = File.basename(candidates[0])
          else
            say "More than one package version found, please choose one of:"
            l = candidates.map { |c| colored_path(c.gsub(package_dir + '/','')) }
            say $terminal.list(l,:columns_across)
            say "\n"
            raise InvalidSelectionError, 'Multiple versions found.'
          end
        end
      end

      def normalized_package_path
        @normalized_package_path ||= File.join(@type, @name, version)
      end

      def depot_path
        @depot_path ||= Depot.hash_path_for(depot)
      end
    end
  end
end
