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

      attr_accessor :package_path, :depot, :ignore_bad_package, :ignore_elf, :ignore_pattern
      delegate :say, :with_spinner, :doing, :title, :colored_path, :to => IoHandler

      def initialize(package_path, depot, ignore_bad_package, ignore_elf, ignore_pattern)
        self.package_path = package_path.gsub(/([\[\]\{\}\*\?\\])/, '\\\\\1')
        self.depot = depot
        self.ignore_bad_package = ignore_bad_package
        self.ignore_elf = ignore_elf
        self.ignore_pattern = ignore_pattern
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

          if @type == 'compilers'
            export_compiler(h, dir)
          else
            export_package(h, dir)
          end
        end
      end

      private

      def export_compiler(h, dir)
        dest_pkg_dir = File.join(dir, ENV['cw_DIST'], 'pkg', 'compilers', @name)
        dest_compiler_module_dir = File.join(dir, ENV['cw_DIST'], 'etc', 'modules', 'compilers', @name)
        dest_lib_module_dir = File.join(dir, ENV['cw_DIST'], 'etc', 'modules', 'libs', @name)
        dest_depends_dir = File.join(dir, ENV['cw_DIST'], 'etc', 'depends')
        FileUtils.mkdir_p(dest_pkg_dir)
        FileUtils.mkdir_p(dest_compiler_module_dir)
        FileUtils.mkdir_p(dest_lib_module_dir)
        FileUtils.mkdir_p(dest_depends_dir)

        title "Export"

        compiler_module_file = File.join(Config.modules_dir(depot), 'compilers', @name, version)
        lib_module_file = File.join(Config.modules_dir(depot), 'libs', @name, version)
        pkg_dir = File.join(package_dir, 'compilers', @name, version)
        depends_file = File.join(Config.dependencies_dir(depot), "compilers-#{@name}-#{version}.sh")
        dest_compiler_module_file = File.join(dest_compiler_module_dir, version)
        dest_lib_module_file = File.join(dest_lib_module_dir, version)

        doing "Prepare"
        with_spinner do
          FileUtils.cp_r(pkg_dir, dest_pkg_dir)
          FileUtils.cp_r(compiler_module_file, dest_compiler_module_dir)
          FileUtils.cp_r(lib_module_file, dest_lib_module_dir)
          if File.exists?(depends_file)
            FileUtils.cp_r(depends_file, dest_depends_dir)
          end
        end
        say 'OK'.color(:green)

        doing "Ready"
        with_spinner do
          s = File.read(dest_compiler_module_file).gsub(depot_path,'_DEPOT_')
          File.write(dest_compiler_module_file,s)
          s = File.read(dest_lib_module_file).gsub(depot_path,'_DEPOT_')
          File.write(dest_lib_module_file,s)
        end

        rewritten_files, bad_files = detect_bad_paths(dest_pkg_dir, depot_path)
        h[:rewritten] = rewritten_files

        File.write(File.join(dir,'metadata.yml'), h.to_yaml)
        if bad_files.any?
          if ignore_bad_package
            say "#{'WARNING!'.color(:yellow)} Package contains hard-coded directory (#{bad_files.join(', ')})"
          else
            raise PackageError, "Package contains hard-coded directory (#{bad_files.join(', ')})"
          end
        else
          say 'OK'.color(:green)
        end

        archive(dir)
      end

      def export_package(h, dir)
        dest_pkg_dir = File.join(dir, ENV['cw_DIST'], 'pkg', normalized_package_path)
        dest_module_dir = File.join(dir, ENV['cw_DIST'], 'etc', 'modules', normalized_package_path)
        dest_depends_dir = File.join(dir, ENV['cw_DIST'], 'etc', 'depends')

        FileUtils.mkdir_p(dest_pkg_dir)
        FileUtils.mkdir_p(dest_module_dir)
        FileUtils.mkdir_p(dest_depends_dir)

        basename, variant = @name.split('_')
        md = Repository.map do |r|
          r.packages.select do |p|
            p.type == @type && p.name == basename && p.version == version
          end
        end.flatten.first

        @tags.each do |tag|
          title "Export (#{tag})"

          fqpn = File.join(normalized_package_path, tag)
          module_file = File.join(Config.modules_dir(depot), fqpn)
          depends_file = File.join(Config.dependencies_dir(depot), "#{[@type, @name, @version, tag].join('-')}.sh")
          pkg_dir = File.join(package_dir, fqpn)
          dest_module = File.join(dest_module_dir,tag)

          doing "Prepare"
          with_spinner do
            FileUtils.cp_r(pkg_dir, dest_pkg_dir)
            FileUtils.cp_r(module_file, dest_module_dir)
            if File.exists?(depends_file)
              FileUtils.cp_r(depends_file, dest_depends_dir)
            end
          end
          say 'OK'.color(:green)

          doing "Ready"
          bad_files = []
          with_spinner do
            # modify depot in modulefiles
            p = Package.first(name: @name, type: @type, version: version, tag: tag)
            reqs = md.base_requirements(:runtime) + \
                   md.compiler_requirements(p.compiler_tag,:runtime) + \
                   md.variant_requirements(variant, :runtime)

            s = File.read(dest_module).gsub(depot_path,'_DEPOT_')
            File.write(dest_module,s)
            rewritten_files, bad_files = detect_bad_paths(File.join(dest_pkg_dir,tag), depot_path)

            h[:taggings] << {
              tag: tag,
              compiler_tag: p.compiler_tag,
              requirements: reqs,
              rewritten: rewritten_files
            }
          end
          if bad_files.any?
            if ignore_bad_package
              say "#{'WARNING!'.color(:yellow)} Package contains hard-coded directory (#{bad_files.join(', ')})"
            elsif ignore_pattern
              real_bad_files = bad_files.reject(&ignore_pattern)
              if real_bad_files.any?
                raise PackageError, "Package contains hard-coded directory (#{real_bad_files.join(', ')})"
              else
                say "#{'WARNING!'.color(:yellow)} Ignoring hard-coded directory (#{bad_files.join(', ')}"
              end
            else
              raise PackageError, "Package contains hard-coded directory (#{bad_files.join(', ')})"
            end
          else
            say 'OK'.color(:green)
          end
        end
        File.write(File.join(dir,'metadata.yml'), h.to_yaml)

        archive(dir)
      end

      def text_file?(file)
        run(['file',file]) do |r|
          r.success? && r.stdout.include?("text")
        end
      end

      def elf_file?(file)
        run(['file',file]) do |r|
          r.success? && r.stdout.include?("ELF")
        end
      end

      def detect_bad_paths(dir, depot_path)
        # warn about depot specifics in package code
        run(['grep','-lr',depot_path,dir]) do |r|
          if r.success?
            out = r.stdout
            rewritten_files = []
            bad_files = []
            out.split("\n").each do |f|
              if text_file?(f)
                s = File.read(f).gsub(depot_path,'_DEPOT_')
                File.write(f,s)
                rewritten_files << f.gsub(File.join(dir,''),'')
              elsif ignore_elf && elf_file?(f)
                # accept ELF binaries which don't have hardcoded lib paths
                run(['ldd',f]) do |r|
                  r.stdout.each_line do |l|
                    if l =~ /^\S*#{depot_path}.*=>/
                      bad_files << f.gsub(File.join(dir,''),'')
                    end
                  end
                end
              else
                bad_files << f.gsub(File.join(dir,''),'')
              end
            end
            [rewritten_files,bad_files]
          else
            [[],[]]
          end
        end
      end

      def archive(dir)
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

      def setup
        @type, @name, @version, tag = package_path.split('/')
        @tags =
          if @type == 'compilers'
            @tags = ['']
          elsif tag && File.directory?(File.join(package_dir, @type, @name, version, tag))
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

      def fqpn(tag)
        @fqpn ||=
          if @type == 'compilers'
            normalized_package_path
          else
            File.join(normalized_package_path, tag)
          end
      end

      def version
        return @version unless @version.nil?
        if @version.nil?
          candidates = Dir.glob(File.join(package_dir, @type, @name, '*'))
          if candidates.length == 0
            raise NotFoundError, "Could not find package for: #{File.join(@type, @name)}"
          elsif candidates.length == 1
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
