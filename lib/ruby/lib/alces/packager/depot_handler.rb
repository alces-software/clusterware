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
require 'net/http'
require 'alces/packager/depot_repo'
require 'alces/packager/definition_handler'

module Alces
  module Packager
    class DepotHandler
      ACTIONS_REQUIRING_DEPOT_REPO_UPDATE = [
        :info,
        :install,
        :list
      ]

      class << self
        def handle(options)
          ENV['cw_GRIDWARE_notify'] = 'false' unless options.notify
          handler_opts = OptionSet.new(options)
          op = options.args.first
          handler_opts.args = options.args[1..-1]
          @handler = new(handler_opts)
          instance_methods(false).each do |m|
            if is_method_shortcut(op, m)
              if [:info, :init, :install].include?(m) && op.length < 3
                raise DepotError, "Ambiguous depot operation: #{op} (maybe: info, init, install?)"
              elsif [:export, :enable].include?(m) && m =~ op.length < 2
                raise DepotError, "Ambiguous depot operation: #{op} (maybe: enable, export?)"
              end
              if action_requires_depot_repo_update?(m)
                update_depot_repositories
              end
              @handler.send(m)
              return
            end
          end
          raise DepotError, "Unrecognised depot operation: #{op}"
        end

        def action_requires_depot_repo_update?(action)
          ACTIONS_REQUIRING_DEPOT_REPO_UPDATE.include? action
        end

        def update_depot_repositories
          repos_requiring_update = DepotRepo.requiring_update
          say_repos_requiring_update_message(repos_requiring_update)
          repos_requiring_update.map do |repo|
            @handler.update_repository(repo)
          end
        end

        def say_repos_requiring_update_message(repos_requiring_update)
          if repos_requiring_update.any?
            num_repos = repos_requiring_update.length
            repo_needs_str = num_repos  > 1 ? 'repositories need' : 'repository needs'
            say "#{repos_requiring_update.length} #{repo_needs_str} to update ..."
          end
        end

        def remote_package_exists?(path)
          url = URI.parse(path)
          resp = Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == 'https') do |http|
            http.open_timeout = 2
            http.read_timeout = 2
            http.head(url.path)
          end
          resp.code == "200"
        end

        def archive_path_for(root, name)
          "#{root}/#{name.tr('/','-')}-#{ENV['cw_DIST']}.tar.gz"
        end

        def is_method_shortcut(operation, method_identifier)
          is_prefix = method_identifier =~ /^#{Regexp.escape(operation)}/
          is_list_shortcut = method_identifier == :list && operation == 'ls'
          is_prefix || is_list_shortcut
        end
      end

      delegate :say, :confirm, :doing, :colored_path, to: IoHandler
      delegate :remote_package_exists?, :archive_path_for, to: self

      attr_accessor :options
      def initialize(options)
        self.options = options
      end

      def update
        # update the specified repo, or 'official' if none specified
        depot_repo_name = options.args.first || 'official'
        repo = DepotRepo.get(depot_repo_name)
        raise NotFoundError, "Repository '#{depot_repo_name}' not found" if repo.nil?
        update_repository(repo)
      end

      def update_repository(repo)
        say "Updating depot repository: #{repo.name}"
        doing 'Update'
        begin
          status, rev = repo.update!
          case status
          when :ok
            say "#{'OK'.color(:green)} (At: #{rev})"
          when :uptodate
            say "#{'OK'.color(:green)} (Up-to-date: #{rev})"
          when :not_updateable
            say "#{'SKIP'.color(:yellow)} (Not updateable, no remote configured)"
          when :outofsync
            say "#{'SKIP'.color(:yellow)} (Out of sync: #{rev})"
          end
        rescue
          say "#{'FAIL'.color(:red)} (#{$!.message})"
        end
      end

      def list
        depots = DepotRepo.all.map(&:depots).flatten
        if options.oneline
          Alces::Packager::CLI.send(:enable_paging)
          say <<-ERB.chomp
<%= list(#{depots.map { |p| p.name.color(:magenta).bold }.inspect},:rows) %>
          ERB
        else
          cols = $terminal.output_cols
          Alces::Packager::CLI.send(:enable_paging)
          wrap_col = ((cols - 56) * 0.7).floor
          rows = [].tap do |a|
            depots.each do |p|
              a << [
                p.name.color(:magenta).bold,
                p.title
              ]
              a.last << $terminal.wrap(p.metadata[:summary],wrap_col) if cols > 80
              a << :separator
            end
          end
          rows.pop
          headings = ['Name','Title']
          headings << 'Summary' if cols > 80
          Alces::Packager::CLI.send(:enable_paging)
          say Terminal::Table.new(title: 'Gridware Depots',
                                  headings: headings,
                                  rows: rows,
                                  style: {width: cols < 80 ? 80 : cols - 5}).to_s
        end
      end

      def info
        Alces::Packager::CLI.send(:enable_paging)
        say "  #{'Name'.underline}\n    #{depot.title}"
        say "\n  #{'Summary'.underline}\n    #{depot.summary}"
        if depot.metadata[:description]
          say "\n  #{'Description'.underline}\n    "
          say "#{depot.metadata[:description].split("\n").join("\n    ")}"
        end
        say "\n  #{'Packages'.underline}"
        depot.content.each do |pkg|
          say "    #{colored_path(pkg)}"
        end
        say "\n"
      end

      def install
        $terminal.instance_variable_set :@output, STDERR
        raise MissingArgumentError, 'Please supply a depot name' if depot_name.nil?
        say "Installing depot: #{depot_name.color(:magenta).bold}"
        if options.explicit_depot
          if ! Depot.find(options.depot)
            raise NotFoundError, "Target depot not found: #{options.depot}"
          end
        elsif Depot.find(depot_name)
          raise InvalidSelectionError, "Depot already exists: #{depot_name}"
        end

        build_targets =
          if options.compile
            depot.content
          else
            depot.content.reject do |pkg|
              remote_package_exists?(archive_path_for(depot.region_aware_root,pkg))
            end
          end
        if build_targets.any?
          build_targets_str = build_targets.map do |pkg|
            if pkg =~ %r{(.*)/(\S*)_(\S*)/(.*)}
              pkg = "#{$1}/#{$2}/#{$4}"
              variant = $3
            else
              variant = 'default'
            end
            definitions = Repository.find_definitions(pkg)
            if definitions.length == 0
              raise NotFoundError, "No remote or local matching package found for: #{pkg}"
            elsif definitions.length > 1
              raise DepotError, "No remote but more than one local matching package found for: #{pkg}"
            elsif definitions.first.metadata[:variants] &&
                  !definitions.first.metadata[:variants].include?(variant)
              raise DepotError, "No remote and no matching variant for local package: #{colored_path(pkg)} (#{variant})"
            end
            colored_path(pkg).tap do |s|
              s << " (#{variant})" if definitions.first.metadata[:variants]
            end
          end.join(', ')

          if options.binary_only
            raise NotFoundError, "Aborting installation due to missing binary packages: #{build_targets_str}"
          end

          msg = <<EOF

#{'WARNING'.color(:yellow)}: Depot contains the following packages to be built from source:
  #{build_targets_str}

Install these packages from source?
EOF
          unless options.yes || (!options.non_interactive && confirm(msg))
            raise NotFoundError, "Aborting installation due to missing packages: #{build_targets_str}"
          end
        end

        target_depot =
          if !options.explicit_depot
            # initialize new live depot
            Depot.new(depot_name).tap do |d|
              d.init(options.disabled)
              say "\n"
              Dao.initialize!
              Dao.finalize!
            end
          else
            Depot.find(options.depot)
          end

        DataMapper.repository(target_depot.name) do
          # import/install content
          (depot.content - build_targets).each do |pkg|
            # download and import
            import_opts = OptionSet.new(options)
            import_opts.depot = target_depot.name
            ArchiveImporter.import(archive_path_for(depot.region_aware_root,pkg), import_opts)
            say "\n"
          end
          build_targets.each do |pkg|
            # build locally
            variant = pkg.split('/')[1].split('_')[1]
            pkg = (
              pkg.split('/').tap do |parts|
                parts[1] = parts[1].split('_').first
              end.join('/')
            )
            definition = Repository.find_definitions(pkg).first
            o = OptionSet.new(options)
            variant = 'default' if definition.metadata[:variants] && variant.nil?
            o.variant = variant
            o.depot = target_depot.name
            DefinitionHandler.install(definition,o)
          end
        end
      end

      # Remove a depot from the installation
      def purge
        $terminal.instance_variable_set :@output, STDERR
        live_depot.purge(options.yes ? :force : options.non_interactive)
      end

      def enable
        $terminal.instance_variable_set :@output, STDERR
        live_depot.enable
      end

      def disable
        $terminal.instance_variable_set :@output, STDERR
        live_depot.disable
      end

      def init
        $terminal.instance_variable_set :@output, STDERR
        raise MissingArgumentError, 'Please supply a depot name' if depot_name.nil?
        raise DepotError, "Depot already exists: #{depot_name}" if Depot.find(depot_name)
        Depot.new(depot_name).init(options.disabled)
      end

      def export
        live_depot.export(options)
      end

      private
      def depot
        @depot ||= (
          raise MissingArgumentError, 'Please supply a depot name' if depot_name.nil?
          DepotRepo.get_depot(depot_name).tap do |d|
            raise InvalidSelectionError, "No such depot: #{depot_name}" if d.nil?
          end
        )
      end

      def live_depot
        @live_depot ||= (
          raise MissingArgumentError, 'Please supply a depot name' if depot_name.nil?
          Depot.find(depot_name).tap do |d|
            raise NotFoundError, "Depot not installed: #{depot_name}" if d.nil?
          end
        )
      end

      def depot_name
        options.args.first
      end
    end
  end
end
