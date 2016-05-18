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
    class DisplayHandler
      extend Memoist
      include Alces::Tools::Logging

      class << self
        def list(*a)
          new(*a).list
        end
        def search(*a)
          new(*a).search
        end
        def info(*a)
          new(*a).info
        end
      end

      delegate :say, :colored_path, :to => IoHandler
      delegate :sort, :to => Metadata

      attr_accessor :options
      def initialize(options)
        self.options = options
      end

      def list
        if options.full
          details
        else
          summary
        end
      end

      def search
        if options.args.first.nil?
          raise MissingArgumentError, 'Please supply a search string'
        end
        defns = matching_definitions(options.search_args, options.search_opts_hash)
        if options.full
          details(defns, options.args, options.search_opts_hash)
        else
          summary(defns)
        end
      end

      def info
        if options.args.first.nil?
          raise MissingArgumentError, 'Please supply a package name'
        end
        if definitions.empty?
          raise NotFoundError, "Could not find package matching: #{options.args.first}"
        end

        Alces::Packager::CLI.send(:enable_paging)
        sort(definitions).each do |m|
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

      private
      def package_name
        @package_name ||= options.args[0]
      end

      def definitions
        @definitions ||= Repository
                       .find_definitions(package_name || '*')
      end

      def matching_definitions(a, opts)
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

      def summary(defns = definitions)
        mode = options.oneline == true || !STDOUT.tty? ? ':rows' : ':columns_across'
        Alces::Packager::CLI.send(:enable_paging)
        say <<-ERB.chomp
<%= list(#{sort(defns).map { |p| colored_path(p) }.inspect},#{mode}) %>
        ERB
      end

      def details(defns = definitions, highlights = [], search_opts = {})
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
          sort(defns).each do |p|
            a << [
                  highlighter.call(colored_path(p), search_opts[:name]),
                  highlighter.call((p.metadata[:group] || '<Unknown>'), search_opts[:group]).color(:green)
                 ]
            a.last << $terminal.wrap(highlighter.call(p.metadata[:summary] || '<Unknown>', search_opts[:description]),wrap_col) if cols > 80
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

      def print_params_help(defn)
        if defn.metadata[:params] && defn.metadata[:params].any?
          say "\n  #{'Required parameters'.underline} (param=value)\n\n"
          defn.params.each do |k,v|
            say sprintf("%15s: %s\n", k, v)
          end
        end
      end
    end
  end
end
