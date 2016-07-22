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
module Alces
  module Packager
    class OptionSet
      attr_accessor :compiler, :variant, :depot, :args, :tag, :modules, :binary, :binary_depends, :binary_only
      attr_accessor :global, :latest, :yes, :non_interactive, :verbose
      attr_accessor :ignore_bad, :accept_elf, :accept_bad, :patch_binary, :output, :packages, :notify
      attr_accessor :tree, :ignore_satisfied
      attr_accessor :full, :oneline, :groups, :descriptions, :names
      attr_accessor :disabled, :compile, :explicit_depot

      def initialize(options = nil)
        unless options.nil?
          self.compiler = options.compiler
          self.variant = options.variant
          self.depot = options.depot
          self.args = options.args
          self.tag = options.tag
          self.modules = options.modules
          self.binary = options.binary
          self.binary_depends = options.binary_depends
          self.binary_only = options.binary_only

          self.global = options.global
          self.latest = options.latest
          self.yes = options.yes
          self.non_interactive = options.non_interactive
          self.verbose = options.verbose

          self.tree = options.tree
          self.ignore_satisfied = options.ignore_satisfied

          self.ignore_bad = options.ignore_bad
          self.accept_elf = options.accept_elf
          self.accept_bad = options.accept_bad
          self.patch_binary = options.patch_binary
          self.output = options.output
          self.packages = options.packages.nil? ? true : options.packages
          self.notify = options.notify.nil? ? true : options.notify

          self.full = options.full
          self.oneline = options.oneline

          self.groups = options.groups
          self.descriptions = options.descriptions
          self.names = options.names

          self.disabled = options.disabled
          self.explicit_depot =
            if options.explicit_depot.nil?
              !!options.depot
            else
              options.explicit_depot
            end
          self.compile = options.compile
        end

        self.compiler ||= :first
        self.depot ||= (Config.default_depot rescue 'local')
      end

      def search_args
        args.map {|s| Regexp.escape(s)}
      end

      def search_opts_hash
        if !descriptions && !names && !groups
          { group: true, name: true, description: true }
        else
          {
            group: groups || false,
            name: names || false,
            description: descriptions || false
          }
        end
      end
    end
  end
end
