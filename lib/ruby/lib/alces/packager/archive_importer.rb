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
    class ArchiveImporter
      class << self
        def import(*a, &b)
          new(*a, &b).import
        end
      end

      include Alces::Tools::Execution

      attr_accessor :archive_path, :depot, :io
      delegate :say, :with_spinner, :doing, :title, :colored_path, :to => :io
      
      def initialize(archive_path, depot, io)
        self.archive_path = archive_path
        self.depot = depot
        self.io = io
      end

      def import
        say "Importing #{archive_path.color(:cyan)}"

        if archive_path[0..4] == 'http:' || 
           archive_path[0..5] == 'https:'
          title "Fetching archive"
          doing 'Download'
          target = File.expand_path(File.join(Config.archives_dir,'dist',File.basename(archive_path)))
          FileUtils.mkdir_p(File.dirname(target))
          if File.exists?(target)
            say "#{'SKIP'.color(:yellow)} (Existing source file detected)"
          else
            with_spinner do
              timeout = (Config.fetch_timeout rescue nil) || 10
              run(['wget',archive_path,'-T',timeout.to_s,'-t','1','-O',"#{target}.alcesdownload"]) do |r|
                raise DepotError, "Unable to download archive for import." unless r.success?
              end
              FileUtils.mv("#{target}.alcesdownload",target)
            end
            say 'OK'.color(:green)
          end
        else
          raise NotFoundError, "Archive not found at #{archive_path}" if !File.exists?(archive_path)
          target = archive_path
        end

        title "Preparing import"
        Dir.mktmpdir do |dir|
          doing 'Extract'
          with_spinner do
            run(['tar', '-xzf', target, '-C', dir]) do |r|
              raise PackageError, "Unable to extract tarball." unless r.success?
            end
          end
          say 'OK'.color(:green)

          doing 'Verify'
          # read metadata
          load_metadata(dir)
          # verify correct distro
          if distro != ENV['cw_DIST']
            # incompatible
            raise PackageError, "Incompatible distro in archive (#{distro}) for this system (#{ENV['cw_DIST']})"
          end
          say 'OK'.color(:green)
          
          # modify depot in modulefiles
          dest_module_dir = File.join(Config.modules_dir(depot), package_path)
          dest_pkg_dir = File.join(Config.packages_dir(depot), package_path)
          taggings.each do |tagging|
            exists = false
            catch(:done) do
              title "Processing #{package_path}/#{tagging[:tag]}"
              doing "Importing"
              with_spinner do
                # verify not already installed!
                p = Package.first(name: name, type: type, version: version, tag: tagging[:tag])
                if !p.nil?
                  exists = true
                  throw :done
                end
                module_file = File.join(dir, ENV['cw_DIST'], 'etc', 'modules', package_path, tagging[:tag])
                pkg_dir = File.join(dir, ENV['cw_DIST'], 'pkg', package_path, tagging[:tag])
                s = File.read(module_file).gsub('_DEPOT_',depot_path)
                File.write(module_file,s)
                
                Package.first_or_create(type: type,
                                        name: name,
                                        version: version,
                                        compiler_tag: tagging[:compiler_tag],
                                        tag: tagging[:tag])

                # move into place
                FileUtils.mkdir_p(dest_module_dir)
                FileUtils.mv(module_file, dest_module_dir)
                FileUtils.mkdir_p(dest_pkg_dir)
                FileUtils.mv(pkg_dir, dest_pkg_dir)
              end
            end
            if exists
              say 'EXISTS'.color(:yellow)
            else
              say 'OK'.color(:green)
            end
          end

          title "Finalizing import"
          doing 'Update'
          with_spinner do
            ModuleTree.safely do
              Version.write_defaults!(depot)
              Package.write_defaults!(depot)
              Package.write_aliases!(depot)
            end
          end
          say 'OK'.color(:green)
        end
      end

      def method_missing(s, *a, &b)
        if @metadata && @metadata.key?(s)
          @metadata[s]
        else
          super
        end
      end
      
      private
      def load_metadata(dir)
        if File.exist?(File.join(dir,'metadata.yml'))
          @metadata = YAML.load_file(File.join(dir,'metadata.yml'))
        else
          raise PackageError, "Archive does not contain metadata"
        end
      end 

      def package_path
        @package_path ||= File.join(type, name, version)
      end
      
      def depot_path
        @depot_path ||= Depot.hash_path_for(depot)
      end
    end
  end
end