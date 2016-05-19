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
    class DefinitionHandler
      extend Memoist

      class << self
        def install(*a)
          new(*a).install
        end
        def requires(*a)
          new(*a).requires
        end
      end

      delegate :say, :confirm, :title, :colored_path, :to => IoHandler

      attr_accessor :defn, :options
      def initialize(defn, options)
        self.defn = defn
        self.options = options
      end

      def install
        say "Preparing to install #{colored_path(defn)}"
        assert_valid(:install)
        if options.variant
          if defn.metadata[:variants] && options.variant == 'all'
            defn.metadata[:variants].keys.each(&method(:install_defn))
          elsif defn.metadata[:variants] && defn.metadata[:variants].include?(options.variant)
            install_defn(options.variant)
          else
            raise InvalidSelectionError, "Invalid variant '#{options.variant}' for package '#{defn.name}'."
          end
        else
          install_defn
        end
        say "\nInstallation complete."
      end

      def requires
        assert_valid(:requires)
        dh = DependencyHandler.new(defn, selected_compiler, options.variant, options.global, options.ignore_satisfied)
        if options.tree
          dh.print_requirements_tree
        else
          rows = []
          dh.resolve_requirements_tree.each do |req, pkg, installed, build_arg_hash|
            build_args = build_arg_hash.map {|k,v| "#{k}: #{v}"}.join(', ')
            build_args = "-" if build_args == ''
            pkg_path = installed ? colored_path(pkg) + " \u2713".color(:green).bold : colored_path(pkg) + " \u2717".color(:red).bold
            rows << [colored_path(req), pkg_path, build_args]
          end
          headings = ['Requirement','Package','Build arguments']
          Alces::Packager::CLI.send(:enable_paging)
          cols = $terminal.output_cols
          say Terminal::Table.new(title: "Requirements for #{colored_path(defn)}",
                                  headings: headings,
                                  rows: rows
                                 ).to_s
        end
      end

      private
      def assert_valid(action)
        defn.validate!
        validate_variant(action)
        validate_compiler
      end

      def validate_variant(action)
        if defn.metadata[:variants].nil? || defn.metadata[:variants].empty?
          raise InvalidSelectionError, "Invalid variant '#{options.variant}' for package '#{defn.name}' - this package has no variants." if options.variant
        elsif options.variant
          unless defn.variants.include?(options.variant)
            raise InvalidSelectionError, "Invalid variant '#{options.variant}' for package '#{defn.name}' - please choose from: #{defn.variants.keys.join(', ')}" unless action == :install && options.variant == 'all'
          end
        elsif options.variant.nil?
          if action == :requires
            raise InvalidSelectionError, "Select a variant for package '#{defn.name}' - please choose from: #{defn.variants.keys.join(', ')}"
          else
            raise InvalidSelectionError, "Select a variant to build for package '#{defn.name}' - please choose from: #{defn.variants.keys.join(', ')} (or pass 'all' to build all variants)"
          end
        end
      end

      def validate_compiler
        raise InvalidSelectionError, "Invalid compiler '#{selected_compiler}' for package '#{defn.name}' - please choose from: #{defn.compilers.keys.join(', ')}" unless defn.compilers.include?(selected_compiler.split('/').first)
      end

      def install_defn(variant = nil)
        install_dependencies(variant)
        say("Installing #{colored_path(defn)}".tap do |s|
          s << " (#{variant})" unless variant.nil?
            end)
        if options.binary && archive_path = binary_path(defn, variant)
          ArchiveImporter.new(archive_path, options).import
          return
        end
        opts = install_opts.tap do |h|
          h[:variant] = variant unless variant.nil?
        end
        Actions.install(defn, opts, IoHandler)
      end

      def install_dependencies(variant = options.variant)
        dh = DependencyHandler.new(defn, selected_compiler, variant, options.global, options.ignore_satisfied)
        missing = dh.resolve_requirements_tree.reject { |_, _, installed, _| installed }
        missing.pop
        return unless missing.any?

        missing_str = missing.map do |_, pkg, _, build_arg_hash|
          colored_path(pkg).tap do |s|
            if build_arg_hash[:variant] && build_arg_hash[:variant] != 'default'
              s << " (#{build_arg_hash[:variant]})"
            end
          end
        end.join(', ')
        msg = <<EOF

#{'WARNING'.color(:yellow)}: Package requires the installation of the following:
  #{missing_str}

Install these dependencies first?
EOF
        if options.yes || (!options.non_interactive && confirm(msg))
          missing_params = {}
          missing.each do |_, pkg, _, build_arg_hash|
            unless (options.binary || options.binary_depends) && binary_available?(pkg, build_arg_hash[:variant])
              (build_arg_hash[:params] || '').split(',').each do |p|
                if !params(defn)[p.to_sym]
                  (missing_params[pkg] ||= []) << p
                end
              end
            end
          end
          if missing_params.any?
            say "\n#{"ERROR".color(:red).underline}: Required build parameters must be supplied for dependencies:\n\n"
            missing_params.each do |pkg, params|
              say "For #{colored_path(pkg)}:"
              print_params_help(pkg)
              say "\n"
            end
            raise InvalidParameterError, "No values specified for required parameters: #{missing_params.map(&:last).flatten.join(', ')}"
          end

          missing.each do |_, dep, _, build_arg_hash|
            opts = OptionSet.new(options)
            opts.variant = build_arg_hash[:variant].nil? ? nil : build_arg_hash[:variant]
            opts.binary = options.binary || options.binary_depends
            opts.args = [dep.path].tap do |a|
              (build_arg_hash[:params] || '').split(',').each do |p|
                a << "#{p}=#{params(defn)[p.to_sym]}"
              end
            end
            DefinitionHandler.install(dep, opts)
          end
        else
          raise NotFoundError, "Aborting installation due to missing dependencies: #{missing_str}"
        end
      end

      def selected_compiler
        options.compiler == :first ? defn.compilers.keys.first : options.compiler
      end

      def params
        {}.tap do |params|
          a = options.args[1..-1]
          while param = a.shift do
            k,v = param.split('=')
            raise InvalidParameterError, "No value found for parameter '#{k}' -- did you forget the '='?" if v.nil?
            params[k.to_sym] = v
          end
          defn.validate_params!(params)
        end
      rescue InvalidParameterError
        print_params_help(defn)
        say "\n"
        raise
      end
      memoize :params

      def print_params_help(defn)
        if defn.metadata[:params] && defn.metadata[:params].any?
          say "\n  #{'Required parameters'.underline} (param=value)\n\n"
          defn.params.each do |k,v|
            say sprintf("%15s: %s\n", k, v)
          end
        end
      end

      def install_opts
        {
          compiler: selected_compiler,
          variant: options.variant,
          verbose: options.verbose,
          noninteractive: (options.yes ? :force : options.non_interactive),
          tag: options.tag,
          depot: options.depot,
          global: options.global,
          params: params,
          modules: options.modules
        }
      end

      def binary_available?(pkg, variant)
        !binary_path(pkg, variant).nil?
      end

      def binary_path(pkg, variant)
        # try for a binary version first
        archive_name = [pkg.type, pkg.name, pkg.version].tap do |a|
          a[1] = "#{pkg.name}_#{variant}" if variant && variant != 'default'
        end.join('/')
        archive_path = DepotHandler.archive_path_for(Config.default_binary_url,archive_name)
        if DepotHandler.remote_package_exists?(archive_path)
          archive_path
        end
      end
    end
  end
end
