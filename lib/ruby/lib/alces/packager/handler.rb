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
require 'alces/tools/logging'
require 'alces/tools/execution'
require 'alces/packager/config'
require 'alces/packager/depot'
require 'alces/packager/repository'
require 'alces/packager/actions'
require 'alces/packager/archive_exporter'
require 'alces/packager/archive_importer'
require 'alces/packager/errors'
require 'alces/packager/io_handler'
require 'terminal-table'
require 'memoist'

Alces::Tools::Logging.default = Alces::Tools::Logger.new(File::expand_path(File.join(Alces::Packager::Config.log_root,'packager.log')),
                                                         :progname => 'packager',
                                                         :formatter => :full)

module Alces
  module Packager
    class HandlerProxy
      def method_missing(s,*a,&b)
        if Handler.instance_methods.include?(s)
          Bundler.with_clean_env do
            Handler.new(*a).send(s)
          end
        else
          super
        end
      rescue Alces::Tools::CLI::BadOutcome
        say "#{'ERROR'.underline.color(:red)}: #{$!.message}"
        exit(1)
      rescue Interrupt
        say "\n#{'WARNING'.underline.color(:yellow)}: Cancelled by user"
        exit(130)
      end
    end

    class Handler < Struct.new(:args, :options)
      extend Memoist

      include Alces::Tools::Logging
      include Alces::Tools::Execution

      def initialize(*)
        super
        options.default(compiler: :first)
        options.default(groups: false)
        options.default(descriptions: false)
        options.default(names: false)
        options.default(depot: (Config.default_depot rescue 'local'))
        if ":#{ENV['cw_FLAGS']}:" =~ /nocolou?r/ || ENV['cw_COLOUR'] == '0'
          HighLine.use_color = false
        end
      end

      def list
        if options.full
          details(definitions)
        else
          glob = args.first || '*'
          d 'package list requested'
          pkgs = definitions.sort.map { |p| colored_path(p) }
          mode = options.oneline == true || !STDOUT.tty? ? ':rows' : ':columns_across'
          Alces::Packager::CLI.send(:enable_paging)
          say <<-ERB.chomp
<%= list(#{pkgs.inspect},#{mode}) %>
            ERB
        end
      end

      def search
        if args.first.nil?
          raise MissingArgumentError, 'Please supply a search string'
        end
        args.map! {|s| Regexp.escape(s)}
        if !options.descriptions && !options.names && !options.groups
          opts = {
            group: true,
            name: true,
            description: true
          }
          options.groups = true
          options.names = true
          options.descriptions = true
        else
          opts = {
            group: options.groups,
            name: options.names,
            description: options.descriptions
          }
        end
        pkgs = search_metadata(args, opts)
        if options.full
          details(pkgs, args)
        else
          mode = options.oneline == true || !STDOUT.tty? ? ':rows' : ':columns_across'
          Alces::Packager::CLI.send(:enable_paging)
          say <<-ERB.chomp
<%= list(#{pkgs.sort.map { |p| colored_path(p) }.inspect},#{mode}) %>
          ERB
        end
      end
      
      def details(packages, highlights = [])
        highlighter = lambda do |s,t|
          if t
            s.gsub(/(.*)(#{highlights.join('.*')})(.*)/i) do
              $1 + $2.reverse + $3
            end
          else
            s
          end
        end
        cols = $terminal.output_cols
        wrap_col = ((cols - 56) * 0.5).floor
        rows = [].tap do |a|
          packages.sort.each do |p|
            a << [
                  highlighter.call(colored_path(p), options.names),
                  highlighter.call((p.metadata[:group] || '<Unknown>'), options.groups).color(:green)
                 ]
            a.last << $terminal.wrap(highlighter.call(p.metadata[:summary] || '<Unknown>', options.descriptions),wrap_col) if cols > 80
            a << :separator
          end
        end
        rows.pop
        headings = ['Path','Category']
        if cols > 80
          headings << 'Summary' 
        end
        Alces::Packager::CLI.send(:enable_paging)
        say Terminal::Table.new(title: 'Matching Gridware Packages', 
                                headings: headings,
                                rows: rows, 
                                style: {width: cols < 80 ? 80 : cols - 5}).to_s
      end

      def info
        if args.first.nil?
          raise MissingArgumentError, 'Please supply a package name'
        end
        if definitions.empty?
          raise NotFoundError, "Could not find package matching: #{args.first}"
        end

        Alces::Packager::CLI.send(:enable_paging)
        definitions.sort.each do |m|
          say "#{colored_path(m)}:"
          # XXX more info in here
          say "  #{'Name'.underline}\n    #{m.title}"
          say "\n  #{'Summary'.underline}\n    #{m.summary}"
          say "\n  #{'Version'.underline}\n    #{m.version}"
          say "\n  #{'Compatible compilers'.underline} (--compiler)\n    "
          say m.compilers.keys.join("\n    ")
          
          unless m.metadata[:variants].nil?
            say "\n  #{'Available variants'.underline} (--variant)\n    "
            say m.variants.keys.join("\n    ")
          end
          print_params_help(m)
          if m.metadata[:description]
            say "\n  #{'Description'.underline}\n    "
            say "#{m.metadata[:description].split("\n").join("\n    ")}"
          end
          say "\n  #{'Repository'.underline}\n    #{m.repo.name}"
          say "\n" 
        end
      end

      def install
        with_depot do
          return unless validate_metadata!

          #Validate the package before going any further
          say "Installing #{colored_path(metadata)}"
          metadata.validate!
          if metadata.metadata[:variants] && variant == 'all'
            metadata.metadata[:variants].keys.each do |v|
              Actions.install(metadata, action_opts(:install).merge(variant: v), IoHandler)
            end
          else
            Actions.install(metadata, action_opts(:install), IoHandler)
          end
          puts "\nInstallation complete."
        end
      end

      def purge
        with_depot do
          return unless validate_package!
          say "Purging #{colored_path(package)}"
          Actions.purge(package, action_opts(:purge), IoHandler)
        end
      end

      def clean
        with_depot do
          begin
            if validate_package!
              say "Cleaning up #{colored_path(package)}"
              Actions.clean(package, action_opts(:clean), IoHandler)
            end
          rescue
            args.unshift(package_name)
            validate_metadata!
            say "Cleaning up #{colored_path(metadata)}"
            Actions.clean(metadata, action_opts(:clean), IoHandler)
          end
        end
      end

      def update
        # update the specified repo, or 'base' if none specified
        repo_name = args.first || 'base'
        repo = Repository.find { |r| r.name == repo_name }
        raise NotFoundError, "Repository #{repo_name} not found" if repo.nil?
        say "Updating repository: #{repo_name}"
        IoHandler.doing 'Update'
        begin
          case repo.update!
          when :ok
            say 'OK'.color(:green)
          when :uptodate
            say "#{'OK'.color(:green)} (Already up-to-date)"
          when :not_updateable
            say "#{'SKIP'.color(:yellow)} (Not updateable, no remote configured)"
          end
        rescue
          say "#{'FAIL'.color(:red)} (#{$!.message})"
        end
      end

      def default
        with_depot do
          # set the specified package as default
          if (package_path = args.first).nil?
            raise MissingArgumentError, 'Please supply a package path'
          end
          package_parts = package_path.split('/')
          package_prefix = package_parts[0..-2].join('/')
          version = package_parts.last
          package = Package.first(path: package_path) || Version.first(path: package_prefix, version: version)
          raise NotFoundError, "Package '#{colored_path(package_path)}' not found" if package.nil?
          Actions.set_default(package, action_opts(:default), IoHandler)
        end
      end

      def export
        with_depot do
          package_path = args[0]
          raise MissingArgumentError, 'Please supply a package path' if package_path.nil? || !package_path.include?('/')
          ArchiveExporter.export(package_path, options.depot, IoHandler, options.ignore_bad)
        end
      end

      def import
        with_depot do
          archive_path = args[0]
          raise MissingArgumentError, 'Please supply path to archive' if archive_path.nil?

          ArchiveImporter.import(archive_path, options.depot, IoHandler)
        end
      end

      def depot
        $terminal.instance_variable_set :@output, STDERR
        operation = args[0]
        raise MissingArgumentError, 'Please supply the depot operation' if operation.nil?
        case operation
        when 'fetch'
          source_url = args[1]
          name = args[2]
          raise MissingArgumentError, 'Please supply a depot source URL' if source_url.nil?
          depot = Depot.new(source_url: source_url, name: name)
          if depot.fetch
            say "Depot '#{depot.name}' fetched successfully."
          else
            raise InvalidSelectionError, "Depot could not be fetched from: #{source_url}"
          end
        when 'enable'
          target = args[1]
          raise MissingArgumentError, 'Please supply a depot name' if target.nil?
          if depot = Depot.find(target)
            depot.enable
          else
            raise InvalidSelectionError, "No such depot: #{target}"
          end
        when 'disable'
          target = args[1]
          raise MissingArgumentError, 'Please supply a depot name' if target.nil?
          if depot = Depot.find(target)
            depot.disable
          else
            raise InvalidSelectionError, "No such depot: #{target}"
          end
        when 'list'
          Depot.list
        else
          raise InvalidSelectionError, "No such depot operation: #{operation}"
        end
      end

      private
      def colored_path(p)
        IoHandler.colored_path(p)
      end

      def validate_metadata!
        if args.first.nil?
          raise MissingArgumentError, 'Please supply a package name'
        end
        if definitions.length == 0
          raise NotFoundError, "No matching package found for: #{package_name}"
        elsif definitions.length > 1
          l = definitions.map {|p| colored_path(p) }
          say "More than one matching package found, please choose one of:"
          say $terminal.list(l,:columns_across)
          false
        else
          # set compiler to first available if we're using the default
          options.compiler = metadata.compilers.keys.first if options.compiler == :first
          validate_variant
          validate_compiler
          true
        end
      end

      def validate_package!
        if args.first.nil?
          raise MissingArgumentError, 'Please supply a package path'
        end
        if packages.length == 0
          raise NotFoundError, "No matching package found for: #{package_name}"
        elsif packages.length > 1
          l = packages.map {|p| colored_path(p) }
          say "More than one matching package found, please choose one of:"
          say $terminal.list(l,:columns_across)
          false
        else
          true
        end
      end

      def params
        {}.tap do |params|
          a = args.dup
          while param = a.shift do
            k,v = param.split('=')
            raise InvalidParameterError, "No value found for parameter '#{k}' -- did you forget the '='?" if v.nil?
            params[k.to_sym] = v
          end
          metadata.validate_params!(params)
        end
      rescue InvalidParameterError
        print_params_help(metadata)
        say "\n"
        raise
      end

      def action_opts(action)
        {
          compiler: compiler,
          variant: variant,
          verbose: verbose,
          noninteractive: (yes ? :force : non_interactive),
          tag: tag,
          depot: options.depot,
          global: options.global
        }.tap do |h|
          # only need params or modules when installing
          if [:install].include?(action)
            h[:params] = params
            h[:modules] = modules
            if metadata.mode == :unpacker
              h[:skip_validation] = true
              h.delete(:compiler)
            end
          end
        end
      end
      memoize :action_opts

      def validate_compiler
        raise InvalidSelectionError, "Invalid compiler '#{compiler}' for package '#{metadata.name}' - please choose from: #{metadata.compilers.keys.join(', ')}" unless metadata.compilers.include?(compiler.split('/').first)
      end

      def validate_variant
        if metadata.metadata[:variants].nil? || metadata.metadata[:variants].empty?
          raise InvalidSelectionError, "Invalid variant '#{variant}' for package '#{metadata.name}' - this package has no variants." if variant
        elsif !variant.nil?
          raise InvalidSelectionError, "Invalid variant '#{variant}' for package '#{metadata.name}' - please choose from: #{metadata.variants.keys.join(', ')}" unless variant == 'all' || metadata.variants.include?(variant)
        elsif variant.nil?
          raise InvalidSelectionError, "Select a variant to build for package '#{metadata.name}' - please choose from: #{metadata.variants.keys.join(', ')} (or pass 'all' to build all variants)"
        end
      end

      [:tag, :variant, :compiler, :modules, :verbose, :yes, :non_interactive].each do |k|
        define_method(k) do
          # XXX - kinda API private hack here
          options.__hash__[k]
        end
      end

      def package_name
        @package_name ||= args.shift
      end

      def metadata
        definitions.first
      end

      def definitions
        @definitions ||= find_metadata(package_name || '*')
      end

      def package
        packages.first
      end

      def packages
        @packages ||= begin
                        ps = Package.all(:path.like => "#{package_name}")
                        ps.empty? ? Package.all(:path.like => "#{package_name}%") : ps
                      end
      end

      def search_metadata(a, opts)
        re = Regexp.new(a.join('.*'),true)
        Repository.map do |r|
          r.packages.select do |p|
            (opts[:description] &&
              ((p.metadata[:description] || '') =~ re ||
               (p.metadata[:summary] || '') =~ re ||
               (p.metadata[:title] || '') =~ re)) ||
              (opts[:group] &&
               (p.metadata[:group] || '') =~ re) ||
              (opts[:name] &&
               p.name =~ re)
          end
        end.flatten
      end
      
      def find_metadata(a)
        Repository.map do |r|
          r.packages.select do |p|
            if (parts = a.split('/')).length == 1
              File.fnmatch?(a, p.name, File::FNM_CASEFOLD)
            elsif parts.length == 2
              # one of repo/type, type/name or name/version
              File.fnmatch?(a, "#{p.repo.name}/#{p.type}", File::FNM_CASEFOLD) || File.fnmatch?(a, "#{p.type}/#{p.name}", File::FNM_CASEFOLD) || File.fnmatch?(a, "#{p.name}/#{p.version}", File::FNM_CASEFOLD)
            elsif parts.length == 3
              # one of repo/type/name or type/name/version
              File.fnmatch?(a, "#{p.repo.name}/#{p.type}/#{p.name}", File::FNM_CASEFOLD) || File.fnmatch?(a, "#{p.type}/#{p.name}/#{p.version}", File::FNM_CASEFOLD)
            elsif parts.length == 4
              if File.fnmatch?(a, p.path, File::FNM_CASEFOLD)
                true
              else
                if File.fnmatch?(parts[0..2].join('/'), "#{p.type}/#{p.name}/#{p.version}", File::FNM_CASEFOLD)
                  options.tag = parts[3]
                  true
                end
              end
            end
          end
        end.flatten
      end
      
      def print_params_help(m)
        if m.metadata[:params] && m.metadata[:params].any?
          say "\n  #{'Required parameters'.underline} (param=value)\n\n"
          m.params.each do |k,v|
            say sprintf("%15s: %s\n", k, v)
          end
        end
      end

      def with_depot(&block)
        if Depot.find(options.depot)
          DataMapper.repository(options.depot, &block)
        else
          raise NotFoundError, "Could not find depot: #{options.depot}"
        end
      end
    end
  end
end
