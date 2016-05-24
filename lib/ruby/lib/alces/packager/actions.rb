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
require 'alces/tools/file_management'
require 'alces/tools/execution'
require 'alces/tools/logging'
require 'erb'
require 'alces/packager/module_tree'
require 'alces/packager/package'
require 'alces/packager/errors'
require 'alces/packager/config'
require 'memoist'
require 'find'

module Alces
  module Packager
    class Actions
      class << self
        def method_missing(s, *a, &b)
          if method_defined?(s)
            new(*a).send(s)
          else
            super
          end
        end

        def time_str
          @time_str ||= Time.now.strftime('%Y%m%d%H%M%S')
        end
      end

      extend Memoist
      include Alces::Tools::FileManagement
      include Alces::Tools::Execution
      include Alces::Tools::Logging

      attr_accessor :package, :opts, :io

      delegate :utter, :say, :confirm, :with_spinner, :doing, :title, :tty?, :colored_path, :to => :io

      def initialize(package, opts, io, &block)
        self.package = package
        self.opts = opts
        self.io = io
        block.call(self) if block
      end

      def missing_requirements(modules)
        [].tap do |a|
          modules.each do |req, resolved|
            a << req if resolved.nil?
          end
        end
      end

      def preflight
        unless compilerless?
          v = opts[:compiler].split('/')[1]
          if Package.compiler(compiler_type, v).nil?
            raise NotFoundError, "Unable to locate compiler: #{[compiler_type,v].compact.join('/')}"
          end
        end
        unless (missing = missing_requirements(compile_modules)).empty?
          raise NotFoundError, "Unable to satisfy compilation requirements: #{missing.join(', ')}"
        end
        unless (missing = missing_requirements(tool_modules)).empty?
          raise NotFoundError, "Unable to satisfy build tool requirements: #{missing.join(', ')}"
        end
        unless (missing = missing_requirements(runtime_modules)).empty?
          raise NotFoundError, "Unable to satisfy runtime requirements: #{missing.join(', ')}"
        end

        raise InstallDirectoryError, "Package installation directory already exists: #{dest_dir}, try a 'purge'" if File.exists?(dest_dir)
        if m = ModuleTree.find(opts[:depot], modulefile_name)
          raise ModulefileError, "Modulefile already exists: #{modulefile_name}, try a 'purge'"
        end
        raise BuildDirectoryError, "Build directory already exists: #{build_dir}, try a 'clean'" if File.exists?(build_dir)
      end

      def interactive_preflight(skip_build_dir = false)
        begin
          preflight
        rescue BuildDirectoryError
          unless skip_build_dir
            if opts[:noninteractive] == true
              raise
            elsif opts[:noninteractive] == :force
              clean
              retry
            else
              msg = <<EOF

#{'WARNING'.color(:yellow)}: Build directory already exists:
  #{build_dir}

Proceed with a clean?
EOF
              if confirm(msg)
                clean
                retry
              else
                raise
              end
            end
          end
        rescue InstallDirectoryError, ModulefileError
          if opts[:noninteractive] == true
            raise
          elsif opts[:noninteractive] == :force
            purge(clean: !skip_build_dir) ? retry : raise
          else
            msg = case $!
                  when InstallDirectoryError
                    <<EOF

#{'WARNING'.color(:yellow)}: Package installation directory already exists:
  #{dest_dir}
EOF
                  when ModulefileError
                    <<EOF

#{'WARNING'.color(:yellow)}: Modulefile already exists:
  #{modulefile_name}
EOF
                  end
            msg << "\nProceed with a purge?"
            if confirm(msg)
              purge(clean: !skip_build_dir) ? retry : raise
            else
              raise
            end
          end
        end
      end
      
      def prepare
        title 'Preparing package sources'
        mkdir_p(package.archive_dir)
        prepare_package
        download_sources
        title 'Preparing for installation'
        create_build_area
        if default_unpack?
          unpack_tarball 
        else
          unpack_package
        end
        analyse_package if analyse?
        satisfy_dependencies
        patch_source
      end

      def satisfy_dependencies
        s = dependency_script(:build)
        unless s.nil?
          doing 'Dependencies'
          with_spinner do
            res = with_temp_file(s) do |f|
              run('/bin/bash',f)
            end
            handle_failure!(res,'dependency') if res.fail?
          end
          say 'OK'.color(:green)
        end
      end

      def install
        interactive_preflight
        prepare
        title 'Proceeding with installation'
        compile
        create_install_dir
        install_package
        install_modulefiles
        write_dependencies
      end

      def compile
        doing 'Compile'
        with_spinner do
          res = with_temp_file(compilation_script) do |f|
            run('/bin/bash',f)
          end
          handle_failure!(res,'compilation') if res.fail?
        end
        say 'OK'.color(:green)
      end

      def unpack_package
        doing 'Prepare'
        with_spinner do
          res = with_temp_file(unpack_script) do |f|
            run('/bin/bash',f)
          end
          handle_failure!(res,'preparation') if res.fail?
        end
        say 'OK'.color(:green)
      end

      def analyse?
        package.metadata.key?(:analyse)
      end

      def analyse_package
        doing 'Anaylse'
        with_spinner do
          res = with_temp_file(analysis_script) do |f|
            run('/bin/bash',f)
          end
          if res.fail?
            handle_failure!(res,'analysis')
          else
            yaml = res.stdout.chomp
            h = YAML.load(yaml)
            if h == false
              # no output, assume nothing to do
            elsif h[:failure]
              raise PackageError, h[:failure]
            else
              @analysis_opts = h
              unmemoize_all
            end
          end
        end
        say 'OK'.color(:green)
        interactive_preflight(true)
      end

      def default_prepare?
        !package.metadata.key?(:prepare)
      end

      def prepare_package
        if default_prepare?
          width = (([File.basename(package.file)] + package.sources).map { |x| File.basename(x).length }.max)
          if package.packaged_file?(package.src)
            doing "Packaged --> #{package.src}#{' ' * (width - package.src.length)}", width + 17
            say 'OK'.color(:green)
          else
            doing "Download --> #{File.basename(package.file)}#{' ' * (width - File.basename(package.file).length)}", width + 17
            source_urls = package.source_urls << package.fallback_source_url
            c = 1
            if File.exists?(package.file)
              say "#{'SKIP'.color(:yellow)} (Existing source file detected)"
            else
              download(source_urls, package.file)
              say 'OK'.color(:green)
            end
          end
          begin
            verify_source(package.file, package.src, width, package.source_md5sum)
          rescue PackageError
            c += 1
            source_urls.shift
            if source_urls.any?
              say 'FAILED'.color(:red)
              doing "Download [#{c}] --> #{File.basename(package.file)}#{' ' * (width - File.basename(package.file).length)}", width + 13
              download(source_urls, package.file)
              say 'OK'.color(:green)
              retry
            else
              raise
            end
          end
        else
          doing 'Prepare'
          with_spinner do
            res = with_temp_file(prepare_script) do |f|
              run('/bin/bash',f)
            end
            handle_failure!(res,'preparation') if res.fail?
          end
          say 'OK'.color(:green)
        end
      end

      def install_package
        doing 'Install'
        with_spinner do
          res = with_temp_file(installation_script) do |f|
            run('/bin/bash',f)
          end
          handle_failure!(res,'installation') if res.fail?
          correct_permissions
        end
        say 'OK'.color(:green)
      end

      def write_dependencies
        if package.metadata[:dependencies]
          doing 'Dependencies'
          with_spinner do
            s = dependency_script(:runtime)
            if !s.nil?
              mkdir_p(Config.dependencies_dir(opts[:depot]))
              File.write(dependency_file, s)
            end
          end
          say 'OK'.color(:green)
        end
      end
      
      def install_modulefiles
        doing 'Module'
        with_spinner do
          module_opts = {
            requirements: runtime_modules.map{|p,r|r},
            tag: opts[:tag] || generated_tag,
            params: opts[:params],
            modules: required_modules
          }.tap do |h|
            unless compilerless?
              h[:compiler_tag] = compiler_tag
              h[:compiler] = compiler_module
            end
            unless variant_name.nil? || variant_name == 'default'
              h[:name] = "#{package.name}_#{variant_name}"
            end
          end
          if package.type == 'ext'
            module_opts[:version] = version
            package.modules.each do |defn|
              if defn[:content].is_a?(Hash)
                package.metadata[:module_content] = {}.tap do |h|
                  defn[:content].each do |k,v|
                    h[k] = ERB.new(v).result(binding)
                  end
                end
              else
                package.metadata[:module_content] = ERB.new(defn[:content]).result(binding)
              end
              defn_opts = {}.tap do |h|
                h[:type] = defn[:type]
                if defn.key?(:name)
                  h[:name] = defn[:name]
                  h[:version] = analysis_opts[:"#{defn[:name]}_version"] if analysis_opts.key?(:"#{defn[:name]}_version")
                end
                h[:tag] = defn[:tag] if defn.key?(:tag)
                h[:tag] = nil if defn[:type] == 'compilers'
              end
              ModuleTree.set(opts[:depot], package, module_opts.merge(defn_opts))
            end
          else
            if package.metadata[:module].is_a?(Hash)
              package.metadata[:module_content] = {}.tap do |h|
                package.metadata[:module].each do |k,v|
                  h[k] = ERB.new(v).result(binding)
                end
              end
            else
              package.metadata[:module_content] = ERB.new(package.metadata[:module]).result(binding)
            end
            ModuleTree.set(opts[:depot], package, module_opts)
          end
        end
        say 'OK'.color(:green)
      end

      def clean
        doing 'Clean'
        msg = nil
        with_spinner do
          unless File.directory?(build_dir)
            msg = "Matching build directory was not found: #{build_dir}" 
          else
            rm_r(build_dir)
          end
        end
        if msg
          say "#{'SKIP'.color(:yellow)} (#{msg})"
        else
          say 'OK'.color(:green)
        end
      end

      def purge(purge_opts = {})
        purge_opts = {clean: true}.merge(purge_opts)
        if opts[:noninteractive] == true
          raise InstallDirectoryError, "Refusing to purge non-interactively; supply the --yes option to override"
        elsif opts[:noninteractive] != :force
          files = [].tap do |a|
            a << dest_dir if File.directory?(dest_dir)
            a << dependency_file if File.exists?(dependency_file)
            if m = ModuleTree.find(opts[:depot], modulefile_name)
              a << m 
            end
          end
          if !package.is_a?(Package) && files.empty?
            raise NotFoundError, "Neither a matching package directory (#{dest_dir}) or modulefile (#{modulefile_name}) was found"
          elsif files.empty?
            files << "#{modulefile_name} (MISSING)"
          end
          msg = <<EOF
Purge operation will remove the following files/directories:
  #{files.join("\n  ")}
EOF
          return false unless confirm(msg)
        end
        doing 'Purge'
        with_spinner do
          rm_r(dest_dir) if File.exists?(dest_dir)
          FileUtils.rmdir(File.dirname(dest_dir))
          FileUtils.rmdir(File.dirname(File.dirname(dest_dir)))
          # rm(modulefile_name) if File.exists?(modulefile_name)
          ModuleTree.remove(opts[:depot], modulefile_name)
        end
        say 'OK'.color(:green)
        clean if purge_opts[:clean]
        true
      end

      def set_default
        # in this case, package is a Package object or a Version object, not a Metadata object
        case package
        when Package
          say "Setting #{colored_path(package.path)} as default for #{colored_path(package.path.split('/')[0..-2].join('/'))}:"
        when Version
          say "Setting #{colored_path([package.path,package.version].join('/'))} as default for #{colored_path(package.path)}:"
        end
        doing 'Setting'
        case package
        when Package
          if package.type == 'compilers'
            packages = Package.all(name: package.name)
          else
            packages = Package.all(name: package.name, version: package.version)
          end
          packages.each do |p|
            if p.id != package.id
              p.default = false
            else
              p.default = true
            end
            p.save! # skip save hook
          end
          version_path = File.join(package.type, package.name)
        when Version
          version_path = package.path
        end
        Version.all(path: version_path).each do |v|
          if v.version != package.version
            v.default = false
          else
            v.default = true
          end
          v.save! # skip save hook
        end
        case package
        when Package
          Package.write_defaults!(opts[:depot])
        when Version
          Version.write_defaults!(opts[:depot])
        end
        Package.write_aliases!(opts[:depot])
        say 'OK'.color(:green)
      end

      def create_build_area
        #create build directory
        doing 'Mkdir'
        with_spinner do
          mkdir_p(build_dir)
          raise PackageError, "Unable to create build directory." unless File.directory?(build_dir)
        end
        say "#{'OK'.color(:green)} (#{build_dir})"
      end

      def download_sources
        a = (package.file.nil? ? [] : [File.basename(package.file)])
        width = ((a + package.sources).map { |x| File.basename(x).length }.max)
        package.each_source do |s|
          if package.packaged_file?(s)
            doing "Packaged --> #{s}#{' ' * (width - s.length)}", width + 17
            say 'OK'.color(:green)
          else
            c = 1
            f = package.source_file(s)
            doing "Download --> #{s}#{' ' * (width - s.length)}", width + 17
            if File.exists?(f)
              say "#{'SKIP'.color(:yellow)} (Existing source file detected)"
            else
              source_urls = package.source_urls(package.source_fetch_file(s))
              download(source_urls, f)
              say 'OK'.color(:green)
            end
            begin
              verify_source(f, s, width, package.source_md5sum(package.source_md5sum_file(s)))
            rescue PackageError
              c += 1
              source_urls.shift
              if source_urls.any?
                say "#{'FAILED'.color(:red)} (#{u})"
                doing "Download [#{c}] --> #{File.basename(f)}#{' ' * (width - File.basename(f).length)}", width + 13
                download(source_urls, f)
                say 'OK'.color(:green)
                retry
              end
            end
          end
        end
      end

      def download(urls, target)
        urls.each_with_index do |u, idx|
          # doing " \n Trying --> #{u}"
          begin
            timeout = (Config.fetch_timeout rescue nil) || 10
            with_spinner do
              # XXX - replace this with something neater
              run(['wget',u,'-T',timeout.to_s,'-t','1','-O',"#{target}.alcesdownload"]) do |r|
                raise PackageError, "Unable to download source." unless r.success?
              end
              FileUtils.mv("#{target}.alcesdownload",target)
            end
            break
          rescue PackageError
            # say "#{'FAILED'.color(:red)} (#{u})"
            raise if idx + 1 == urls.length
          end
        end
      end

      def verify_source(fullname, basename, width, md5sum = nil)
        doing "Verify --> #{basename}#{' ' * (width - basename.length)}", width + 17
        if md5sum
          verify(basename, fullname, md5sum)
          say 'OK'.color(:green)
        else
          say "#{'SKIP'.color(:yellow)} (No checksum available)"
        end
      end

      def verify(src, target, md5sum)
        with_spinner do
          run(['md5sum','--check','-'],stdin: md5sum.gsub(src, target)) do |r|
            raise PackageError, 'Package checksum failed, aborting installation.' unless r.success?
          end
        end
      end

      def default_unpack?
        !package.metadata.key?(:unpack)
      end

      def unpack_tarball
        #unpack tar
        doing 'Extract'
        with_spinner do
          ext = File.extname(package.file)
          if ext == '.sic'
            mkdir_p(src_dir)
            cp(package.file, src_dir)
          else
            res = (if ext == '.zip'
                     run(['unzip',package.file,'-d',build_dir])
                   else
                     tar_opts = case ext
                                when '.xz'
                                  'J'
                                when '.bz2'
                                  'j'
                                when '.gz', '.tgz'
                                  'z'
                                when '.tar'
                                  ''
                                else
                                  raise PackageError, 'Unsupported tarball file extension'
                                end
                     run(['tar',"-#{tar_opts}xf",package.file,'-C',build_dir])
                   end)
            if res.fail?
              msg = "Failed to extract tarball"
              if opts[:verbose]
                msg << ", error output follows:\n\n" << res.stderr
              end
              raise PackageError, msg
            end
          end
          raise PackageError, "Source directory does not exist: #{src_dir}" unless opts[:skip_validation] || File.directory?(src_dir)
        end
        say 'OK'.color(:green)
      end

      def patch_source
        return if package.patch_files.empty?
        width = (package.patch_files.map { |x| File.basename(x).length }.max + 17)
        package.patch_files.each do |p|
          doing "Patch --> #{File.basename(p)}", width
          with_spinner do
            #res = patch(src_dir,File.read(p))
            if File.extname(p) =~ /\.patch([0-9])/
              patch_level = $1
            else
              patch_level = 0
            end
            res = run("patch -d #{src_dir} -p#{patch_level} ", stdin: File.read(p))
            if res.fail?
              msg = "Patch failed"
              if opts[:verbose]
                msg << ", error output follows:\n\n" << res.stderr
              end
              raise PackageError, msg
            end
          end
          say 'OK'.color(:green)
        end
      end

      def create_install_dir
        doing 'Mkdir'
        with_spinner do
          mkdir_p(dest_dir)
          raise PackageError, "Unable to create package installation directory." unless File.directory?(dest_dir)
        end
        say "#{'OK'.color(:green)} (#{dest_dir})"
      end

      {
        compile: 'Compilation',
        install: 'Installation'
      }.each do |k,v|
        define_method("#{v.downcase}_script") { script(k,v) }
      end

      def analysis_script
        script(:analyse, 'Analysis', build_dir)
      end

      def unpack_script
        script(:unpack, 'Unpack', build_dir)
      end

      def prepare_script
        script(:prepare, 'Prepare', package.archive_dir)
      end

      def dependency_script(phase)
        if package.metadata[:dependencies]
          case ENV['cw_DIST']
          when /^el/
            generate_dependency_script(phase, 'el', 'rpm -q %s',
                                       "sudo /usr/bin/yum install -y %s >>#{Config.log_root}/depends.log 2>&1",
                                       'env -i yum info %s >/dev/null 2>/dev/null')
          when /^ubuntu/
            generate_dependency_script(phase, 'ubuntu', 'dpkg -l %s',
                                       "sudo /usr/bin/apt-get install -y %s >>#{Config.log_root}/depends.log 2>&1",
                                       'apt-cache show %s >/dev/null 2>/dev/null')
          end
        end
      end

      def script(key, name, working_dir = src_dir)
        ERB.new(template_for(package.metadata[key], working_dir).tap do |t|
                  i("#{name} template"){t} 
                end).result(binding).tap do |t|
          i("#{name} script"){t}               
        end
      end

      def modulefile(locals = {})
        ERB.new(package.metadata[:module].tap do |t|
                  i("Modulefile template"){t}
                end).result(binding).tap do |t|
          i("Evaluated modulefile"){t}
        end
      end

      def variant_name
        opts[:variant]
      end

      private
      def correct_permissions
        FileUtils.chown_R(nil, 'gridware', dest_dir)
        FileUtils.chmod_R("ug+w,a+r", dest_dir, force: true)
        FileUtils.chmod("g+xs,a+x", directories_within(dest_dir))
      end

      def directories_within(base)
        dots = ['.','..']
        [].tap do |a|
          Find.find(base) do |f|
            a << f if File.directory?(f) && !(dots.include?(File.basename(f)))
          end
        end
      end

      def generate_dependency_script(phase, stem, check_cmd, install_cmd, available_cmd)
        deps_hashes = [].tap do |a|
          if package.metadata[:dependencies][phase]
            a << package.metadata[:dependencies][phase]
            if phase == :build && package.metadata[:dependencies].key?(:runtime)
              a << package.metadata[:dependencies][:runtime]
            end
          else
            a << package.metadata[:dependencies]
          end
        end
        deps = deps_hashes.map do |deps_hash|
          [*deps_hash[stem]] + [*deps_hash[ENV['cw_DIST']]]
        end.flatten
        unless deps.empty?
          s = %(deps=()\n)
          deps.each do |dep|
            s << %(if ! #{sprintf(check_cmd,dep)} >/dev/null; then\n  deps+=(#{dep})\nfi\n)
          end
          s << %(
if [ "${#deps[@]}" -gt 0 ]; then
  n=0
  for a in "${deps[@]}"; do
    n=$(($n+1))
    echo -n "Installing distro dependency ($n/${#deps[@]}): ${a} ..."
    if #{sprintf(available_cmd,'"${a}"')}; then
      if ! #{sprintf(install_cmd,'"${a}"')}; then
        echo ' FAILED'
        exit 1
      else
        echo ' OK'
      fi
    else
      echo ' NOT FOUND'
      exit 1
    fi
  done
fi)
          s.tap { i("Dependencies script"){s} }
        end
      end

      def template_for(script_fragment, working_dir = src_dir)
        <<EOF
#{script_prelude(working_dir)}
#{script_fragment}
EOF
      end

      def script_prelude(working_dir)
        # 'set -o errexit' ensures this script is fail fast
        <<EOF
set -x
set -o pipefail
set -o errexit
cd "#{working_dir}"
<%= modules %>
EOF
      end

      def analysis_opts
        @analysis_opts ||= {}
      end

      def version
        analysis_opts[:version] || package.version
      end

      def compiler_type
        opts[:compiler].split('/').first
      end
      alias :compiler_name :compiler_type

      def binary?
        compiler_type == 'bin'
      end

      def noarch?
        compiler_type == 'noarch'
      end

      def compilerless?
        binary? || noarch?
      end

      def compiler?
        package.type == 'compilers'
      end

      def compiler_version
        # XXX - this should be determined by working out what the
        # GRIDWARE_COMPILER_VERSION environment variable is set to
        # in the compiler module.
        opts[:compiler].split('/')[1] || Package.compiler(compiler_type).version
      end

      def compiler_module
        ['compilers', opts[:compiler]].join('/')
      end

      def compiler_tag
        compilerless? ? compiler_type : "#{compiler_type}-#{compiler_version}"
      end

      # a generated tag consists of:
      #   1. the compiler type and compiler version used
      #   2. all library names and versions
      def generated_tag
        constituents = [].tap do |a|
          a << compiler_tag unless compilerless? || compiler?
          compile_modules.map{|p,r|r}.each do |r|
            a << "#{r.name}-#{r.version}" unless r.nil?
          end
        end
        if constituents.empty?
          if compiler?
            nil
          elsif compilerless?
            compiler_type
          else
            'dist'
          end
        else
          constituents.join('+')
        end
      end

      # directory components in which the package should be installed
      def package_descriptor
        case package
        when Package
          package.path.split('/')
        when Metadata
          name = variant_name.nil? || variant_name == 'default' ? package.name : "#{package.name}_#{variant_name}"
          [(package.type == 'ext' ? package.pkg_type : package.type), name, version, opts[:tag] || generated_tag].compact
        end
      end
      memoize :package_descriptor

      def build_dir
        @build_dir ||= File.expand_path(File.join(Config.buildroot, package_descriptor))
      end

      def log_file(name)
        File.expand_path(File.join(Config.log_root,'builds',package_descriptor,"#{name}.#{self.class.time_str}.log"))
      end

      def log_files
        @log_files ||= []
      end

      def dest_dir
        File.expand_path(File.join(Config.packages_dir(opts[:depot]), package_descriptor))
      end
      memoize :dest_dir

      def src_dir
        @src_dir ||= File.expand_path(File.join(build_dir, package.src_dir))
      end

      def modulefile_name
        package_descriptor.join('/')
      end
      memoize :modulefile_name

      def dependency_file
        File.join(Config.dependencies_dir(opts[:depot]),"#{package_descriptor.join('-')}.sh")
      end
      memoize :dependency_file
      
      def compiler
        # XXX - try deeper in the hash for version-specific options?
        package.metadata[:compilers][opts[:compiler].split('/').first]
      end

      def variant
        package.metadata[:variants][opts[:variant]]
      end

      def param(key)
        opts[:params][key.to_sym]
      end

      def runtime_modules
        @runtime_modules ||= modules_for(:runtime)
      end

      def compile_modules
        @compile_modules ||= modules_for(:build)
      end

      def tool_modules
        @tool_modules ||= modules_for(:tool)
      end

      def modules_for(phase)
        if opts[:modules]
          apply_optional_overrides(packages_for(phase))
        else
          packages_for(phase)
        end
      end

      def packages_for(phase)
        package.requirements(opts[:compiler], opts[:variant], phase).
          map{|r| [r, Package.resolve(r, compiler_tag, opts[:global])]}
      end

      def apply_optional_overrides(packages)
        modules = []
        supplied = opts[:modules].split(/[ ,]+/)
        packages.each do |descriptor, p|
          if s = supplied_module(supplied, descriptor)
            modules << [descriptor, Package.resolve(s, compiler_tag, opts[:global])]
            supplied -= [s]
          else
            modules << [descriptor, p]
          end
        end
        overridden = supplied.map{|r| [r, Package.resolve(r,compiler_tag,opts[:global])]} + modules
        unless (missing = missing_requirements(overridden)).empty?
          raise NotFoundError, "Unable to satisfy specified module requirements: #{missing.join(', ')}"
        end
        # Remove any remaining duplicates
        s = []
        overridden.map do |r, p|
          prefix = "#{p.type}/#{p.name}"
          if ! s.include?(prefix)
            s << prefix
            [r,p]
          else
            nil
          end
        end.compact
      end

      def required_modules
        [].tap do |a|
          a << compiler_module unless compilerless?
          a.concat(compile_modules.map{|p,r|r}.map(&:path))
          a.concat(tool_modules.map{|p,r|r}.map(&:path))
        end
      end
      memoize :required_modules

      def supplied_module(modules, match)
        match_parts = match.split('/')[0..2]
        modules.find do |m|
          parts = m.split('/')
          match_parts.all? { |p| p == parts.shift }
        end
      end

      def modules
        modules = required_modules
        module_loading = modules.map do |m|
          "eval `/opt/clusterware/opt/Modules/bin/modulecmd sh load #{m} || echo false`"
        end.join("\n")
        <<-BASH
eval `/opt/clusterware/opt/Modules/bin/modulecmd sh purge || echo false` || true
#{module_loading}
for a in #{modules.join(" ")}; do
  [[ ":$LOADEDMODULES:" =~ ":$a" ]] || false
  done
  BASH
end

      def description
        package.name.dup.tap do |s|
          s << " (variant: #{opts[:variant]})" unless opts[:variant].nil?
        end
      end

      def redirect(stage)
        f = log_file(stage)
        log_files << f
        mkdir_p(File.dirname(f))
        "> >(tee -a #{f}) 2> >(tee -a #{f} >&2)"
      end

      def source(f)
        package.source_file(f)
      end

      def handle_failure!(res, operation)
        msg = "Package #{operation} failed"
        err_lines = res.stderr.split("\n")
        max_lines = err_lines.length > 10 ? 10 : err_lines.length
        msg << "\n\n   Extract of #{operation} script error output:\n   > " << err_lines[-max_lines..-1].reject{|x| !opts[:verbose] && x[0] == '+'}.map(&:strip).join("\n   > ")
        latest_log_file = log_files.reverse.find{|f|File.exists?(f)}
        unless latest_log_file.nil?
          msg << "\n\n   More information may be available in the log file:\n     #{latest_log_file}"
        end
        raise PackageError, msg
      end
    end
  end
end
