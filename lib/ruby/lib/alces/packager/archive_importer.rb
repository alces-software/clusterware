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

      attr_accessor :archive_path, :options
      delegate :say, :with_spinner, :doing, :title, :colored_path, :to => IoHandler

      def initialize(archive_path, options)
        self.archive_path = archive_path
        self.options = options
      end

      def import
        say "Importing #{File.basename(archive_path).color(:cyan)}"

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

          if type == 'compilers'
            import_compiler(dir)
          else
            import_package(dir)
          end

          title "Finalizing import"
          doing 'Update'
          with_spinner do
            ModuleTree.safely do
              Version.write_defaults!(options.depot)
              Package.write_defaults!(options.depot)
              Package.write_aliases!(options.depot)
            end
          end
          say 'OK'.color(:green)
          
          doing 'Dependencies'
          with_spinner do
            Dir.glob(File.join(Config.dependencies_dir(options.depot),"#{type}-#{name}-#{version}*.sh")).each do |f|
              run('/bin/bash',f) do |r|
                raise DepotError, "Unable to resolve dependencies for: #{File.basename(f,'.sh')}" unless r.success?
              end
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
      def import_package(dir)
        # modify depot in modulefiles
        dest_module_dir = File.join(Config.modules_dir(options.depot), package_path)
        dest_pkg_dir = File.join(Config.packages_dir(options.depot), package_path)
        dest_depends_dir = Config.dependencies_dir(options.depot)

        taggings.each do |tagging|
          condition = catch(:done) do
            title "Processing #{package_path}/#{tagging[:tag]}"
            doing 'Preparing'
            # verify not already installed!
            p = Package.first(name: name, type: type, version: version, tag: tagging[:tag])
            if !p.nil?
              throw :done, [:exists, p]
            end

            # verify dependencies are available
            unresolved = (tagging[:requirements] || []).map do |req|
              req if Package.resolve(req, tagging[:compiler_tag]).nil?
            end.compact
            if unresolved.any?
              say "#{'NOTICE'.color(:yellow)}: #{options.compile ? 'building' : 'importing'} requirements"
              say "-" * 80
              unresolved.each do |req|
                if req =~ /(\S*)_(\S*)( .*)?/
                  req = "#{$1}#{$3}"
                  variant = $2
                else
                  variant = 'default'
                end
                defn = DependencyHandler.find_definition(req)
                install_opts = OptionSet.new(options)
                if defn.metadata[:variants] || variant != 'default'
                  install_opts.variant = variant
                end
                install_opts.binary = true unless options.compile
                DefinitionHandler.install(defn, install_opts)
              end
              say "-" * 80
              say "#{'NOTICE'.color(:yellow)}: requirements for #{package_path} satisfied; proceeding to import"
            else
              say 'OK'.color(:green)
            end

            doing "Importing"
            with_spinner do
              module_file = File.join(dir, ENV['cw_DIST'], 'etc', 'modules', package_path, tagging[:tag])
              depends_file = File.join(dir, ENV['cw_DIST'], 'etc', 'depends', "#{[type, name, version, tagging[:tag]].join('-')}.sh")
              pkg_dir = File.join(dir, ENV['cw_DIST'], 'pkg', package_path, tagging[:tag])
              s = File.read(module_file).gsub('_DEPOT_',depot_path)
              File.write(module_file,s)
              (tagging[:rewritten] || []).each do |f|
                fname = File.join(dir, ENV['cw_DIST'], 'pkg', package_path, tagging[:tag], f)
                s = File.read(fname).gsub('_DEPOT_',depot_path)
                File.write(fname,s)
              end

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
              if File.exists?(depends_file)
                s = File.read(depends_file)
                # XXX - bit of a hack!
                File.write(depends_file,s.gsub('if ! yum install', 'if ! sudo /usr/bin/yum install'))
                FileUtils.mkdir_p(dest_depends_dir)
                FileUtils.mv(depends_file, dest_depends_dir)
              end
            end
            nil
          end
          if condition && condition.first == :exists
            say 'EXISTS'.color(:yellow)
          elsif condition && condition.first == :unresolved
            say "#{'MISSING'.color(:red)}\n\n#{'ERROR'.color(:red).underline}: Unable to satisfy runtime requirements: #{condition[1].join(', ')}"
          else
            say 'OK'.color(:green)
          end
        end
      end

      def import_compiler(dir)
        # modify depot in modulefiles
        dest_compiler_module_dir = File.join(Config.modules_dir(options.depot), 'compilers', name)
        dest_lib_module_dir = File.join(Config.modules_dir(options.depot), 'libs', name)
        dest_pkg_dir = File.join(Config.packages_dir(options.depot), 'compilers', name)
        title "Processing #{package_path}"
        doing "Importing"
        exists = false
        catch(:done) do
          with_spinner do
            # verify not already installed!
            p = Package.first(name: name, type: type, version: version)
            if !p.nil?
              exists = true
              throw :done
            end
            compiler_module_file = File.join(dir, ENV['cw_DIST'], 'etc', 'modules', 'compilers', name, version)
            lib_module_file = File.join(dir, ENV['cw_DIST'], 'etc', 'modules', 'libs', name, version)
            pkg_dir = File.join(dir, ENV['cw_DIST'], 'pkg', 'compilers', name, version)
            depends_file = File.join(dir, ENV['cw_DIST'], 'etc', 'depends', "#{['compilers', name, version].join('-')}.sh")
            s = File.read(compiler_module_file).gsub('_DEPOT_',depot_path)
            File.write(compiler_module_file,s)
            s = File.read(lib_module_file).gsub('_DEPOT_',depot_path)
            File.write(lib_module_file,s)
            (rewritten || []).each do |f|
              fname = File.join(dir, ENV['cw_DIST'], 'pkg', 'compilers', name, version, f)
              s = File.read(fname).gsub('_DEPOT_',depot_path)
              File.write(fname,s)
            end
            
            Package.first_or_create(type: type,
                                    name: name,
                                    version: version)

            # move into place
            FileUtils.mkdir_p(dest_compiler_module_dir)
            FileUtils.mv(compiler_module_file, dest_compiler_module_dir)
            FileUtils.mkdir_p(dest_lib_module_dir)
            FileUtils.mv(lib_module_file, dest_lib_module_dir)
            FileUtils.mkdir_p(dest_pkg_dir)
            FileUtils.mv(pkg_dir, dest_pkg_dir)
            if File.exists?(depends_file)
              s = File.read(depends_file)
              # XXX - bit of a hack!
              File.write(depends_file,s.gsub('if ! yum install', 'if ! sudo /usr/bin/yum install'))
              FileUtils.mkdir_p(dest_depends_dir)
              FileUtils.mv(depends_file, dest_depends_dir)
            end
          end
        end
        if exists
          say 'EXISTS'.color(:yellow)
        else
          say 'OK'.color(:green)
        end
      end

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
        @depot_path ||= Depot.hash_path_for(options.depot)
      end
    end
  end
end
