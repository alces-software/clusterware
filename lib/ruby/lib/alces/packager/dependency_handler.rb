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
    class DependencyHandler
      extend Memoist

      attr_accessor :metadata, :compiler, :variant, :global, :ignore_satisfied

      def initialize(metadata, compiler, variant, global, ignore_satisfied)
        self.metadata = metadata
        self.compiler = compiler
        self.variant = variant
        self.ignore_satisfied = ignore_satisfied
      end

      def requirements_tree(ignore_build = false)
        v_str = "#{[metadata.type,metadata.name].join('/')}".tap do |s|
          s << "_#{variant}" if variant
          s << " = #{metadata.version}" unless metadata.version.empty?
        end
        find_requires(Tree::TreeNode.new(v_str), ignore_build)
      end

      def resolve_requirements_tree(root = requirements_tree)
        [].tap do |reqs|
          root.breadth_each do |n|
            path, *rest = n.name.split(/[_ ]/)
            variant = (rest.first =~ /^[A-Za-z]/ ? rest.shift : 'default')
            path = [path, *rest].join(' ')
            req = package_or_definition(path, variant)
            reqs.delete_if {|e| e[1] == req}
            reqs.unshift(
              [
                n.name.gsub('_default',''),
                req,
                installed?(path, variant),
                {}.tap do |h|
                  unless installed?(path, variant)
                    if variant != 'default'
                      h[:variant] = variant
                    elsif req.metadata.key?(:variants) && req.variants.include?('default')
                      h[:variant] = 'default'
                    end
                    if req.metadata.key?(:params)
                      h[:params] = req.params.map do |param, _|
                        "#{param}"
                      end.join(',')
                    end
                  end
                end
              ]
            )
          end
        end.uniq
      end

      def find_requires(node, ignore_build)
        node.tap do
          path = node.name
          if path =~ /(\S*)_(\S*)( .*)?/
            path = "#{$1}#{$3}"
            variant = $2
          else
            variant = 'default'
          end
          if defn = find_definition(path)
            if installed?(path, variant)
              return if ignore_satisfied
              phases = [:runtime]
            elsif ignore_build
              phases = [:runtime]
            else
              phases = [:tool, :runtime, :build]
            end

            selected_compiler = defn.compilers.include?(compiler) ? compiler : defn.compilers.keys.first
            reqs = []
            phases.each do |phase|
              reqs.concat(defn.requirements(selected_compiler, variant, phase)).uniq!
            end
            reqs.each do |r|
              child = find_requires(Tree::TreeNode.new(r), ignore_build)
              node << child unless child.nil?
            end
          end
        end
      end

      def print_requirements_tree(node = requirements_tree, mask = '')
        prefix = ''
        if node.is_root?
          prefix << '*'
        else
          mask[1..-1].each_char do |m|
            prefix << ( m == '.' ? '|    ' : '     ')
          end
          prefix << (node.is_last_sibling? ? '\\' : '|')
          prefix << '----'
          prefix << (node.has_children? ? '+' : '>')
        end

        path = node.name
        if path =~ /(\S*)_(\S*)( .*)?/
          path = "#{$1}#{$3}"
          variant = $2
        else
          variant = 'default'
        end

        p =
          case req = package_or_definition(path, variant)
          when Metadata
            req.version.bold
          when Package
            req.version.color(IoHandler::PRIM) + '/' + req.tag.color(IoHandler::SEC1)
          end
        puts '' << prefix << ' ' << colored_path(node.name) << " -#{installed?(path, variant) ? "-" : "\u2717"}->".color(installed?(path, variant) ? :green : :red).bold << " " << p

        node.children do |child|
          print_requirements_tree(child, mask + (node.is_last_sibling? ? ' ' : '.'))
        end
      end

      def find_definition(req)
        name, op, vers = req.split(' ')
        definitions = Repository.find_definitions(name)
        resolved = Package.resolve_for_version(definitions, op || '>', vers || '0')
        if resolved.nil? && op.nil? && vers.nil?
          definitions.first
        else
          resolved
        end
      end

      def compiler_tag
        ctype, cvers = compiler.split('/')
        if ctype == 'noarch' || ctype == 'bin'
          ctype = 'gcc'
        end
        "#{ctype}-#{cvers || Package.compiler(ctype).version}"
      end
      memoize :compiler_tag

      def installed?(name, variant)
        descriptor =
          if variant == 'default'
            name
          else
            name.split(' ')
              .tap {|a| a[0] = "#{a[0]}_#{variant}"}
              .join(' ')
          end
        !!Package.resolve(descriptor,
                          compiler_tag,
                          global)
      end
      memoize :installed?

      def package_or_definition(name, variant = 'default')
        if installed?(name, variant)
          Package.resolve(name, compiler_tag, global)
        else
          find_definition(name)
        end
      end
      memoize :package_or_definition

      def colored_path(p)
        IoHandler.colored_path(p)
      end
    end
  end
end
