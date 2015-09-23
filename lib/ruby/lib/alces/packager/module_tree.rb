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
require 'alces/tools/file_management'
require 'alces/tools/logging'
require 'alces/packager/errors'
require 'alces/packager/version'
require 'alces/packager/package'
require 'tree'

module Alces
  module Packager
    class ModuleTree
      class << self
        def safely(&block)
          lock_dir = File.expand_path(File.join(Config.buildroot,'lock'))
          begin
            Timeout.timeout(30) do
              loop do
                break unless File.exists?(lock_dir)
                sleep 1
              end
            end
          rescue Timeout::Error
            raise ModulefileError, "Unable to gain module directory lock (stale lock at #{lock_dir}?)"
          end
          begin
            FileUtils.mkdir(lock_dir)
            block.call
          ensure
            FileUtils.rmdir(lock_dir)
          end
        end

        def set(metadata, opts)
          p = Package.first_or_create(type: opts[:type] || metadata.type,
                                      name: opts[:name] || metadata.name,
                                      version: opts[:version] || metadata.version,
                                      compiler_tag: opts[:compiler_tag],
                                      tag: opts[:tag])
          safely do
            tree = new
            p.renderer(metadata, opts).modulefiles.each do |modulepath, modulefile|
              tree.set(modulepath, modulefile)
            end
            tree.persist!
            Version.write_defaults!
            Package.write_defaults!
            Package.write_aliases!
          end
        end

        def find(modulepath)
          tree = new
          tree.find(modulepath)
        end

        def remove(modulepath)
          Package.first(path: modulepath).tap do |p|
            p.destroy unless p.nil?
          end
          safely do
            tree = new
            tree.remove(modulepath)
            tree.persist!
            Version.write_defaults!
            Package.write_defaults!
            Package.write_aliases!
          end
        end

        def versionfile_for(name)
          <<EOF
#%Module1.0#####################################################################
##
## Alces HPC Software Stack - Version selection module file
## Copyright (c) 2008-2012 Alces Software Ltd
##
################################################################################
if { [info exists ::env(ALCES_TRACE)] } {
    puts stderr " -> $::ModulesCurrentModulefile"
}

set ModulesVersion "#{name}"

if { [namespace exists alces] == 0 && [info exists ::env(ALCES_TCL)] } {
    source $::env(ALCES_TCL)
    alces once { alces try-next }
}
EOF
        end
      end

      class ModuleData < Struct.new(:modulefile,:default)
        def default?
          default == true
        end
      end

      include Alces::Tools::Logging
      include Alces::Tools::FileManagement

      attr_accessor :root

      def initialize
        self.root = Tree::TreeNode.new('ROOT')
        populate(Config.modules_dir)
      end

      def set(modulepath, modulefile)
        update_tree(modulepath.split('/'), ModuleData.new(modulefile))
      end

      def node_for(modulepath)
        node = root
        modulepath.split('/').each do |component|
          node = node[component] if node[component]
          if node.is_leaf? && !node.is_root?
            unless path_components(node.content.modulefile).join('/') == modulepath
              node = nil
            end
            return node
          end
        end
        nil
      end

      def find(modulepath)
        node = node_for(modulepath)
        unless node.nil?
          File.join(Config.modules_dir,node.parentage.reverse.map(&:name).tap(&:shift).push(node.name))
        end
      end

      def remove(modulepath)
        purger = lambda do |node|
          parent = node.parent
          node.remove_from_parent!
          purger.call(parent) if !parent.has_children? && parent.content.nil?
        end
        node = node_for(modulepath)
        purger.call(node) unless node.nil?
      end          

      def persist!(path = Config.modules_dir)
        renormalize!
        root_dir = "#{path}.#{$$}"
        root.each_leaf do |l|
          modulefile_dir = File.join(root_dir,l.parentage.reverse.map(&:name).tap(&:shift))
          modulefile_name = File.join(modulefile_dir, l.name)
          mkdir_p(modulefile_dir) rescue nil
          raise PackageError, "Failed to create modules directory #{modulefile_dir}" unless File.directory?(modulefile_dir)
          raise PackageError, "Failed to write module file #{modulefile_name}" unless write(modulefile_name, l.content.modulefile)
        end
        FileUtils.rm_rf(path)
        FileUtils.mv("#{path}.#{$$}", path)
      end

      private
      def modulercfile
        @modulercfile = "#%Module1.0#####################################################################\n\nputs stderr $::ModulesCurrentModulefile\nif { [namespace exists alces] == 0 } { source $::env(ALCES_TCL) }\nalces once { alces try-deeper }"
      end

      def populate(path, node = root)
        Dir[File.join(path,'*')].sort{|a,b| b <=> a }.each do |p|
          name = p[(path.length + 1)..-1]
          if File.directory?(p)
            populate(p, node << Tree::TreeNode.new(name))
          else
            versionfile_name = File.join(File.dirname(p), '.version')
            default = if File.exists?(versionfile_name)
                        default_version?(File.read(versionfile_name), name)
                      else
                        false
                      end
            node << Tree::TreeNode.new(name, ModuleData.new(File.read(p), default))
          end
        end
      end

      def default_version?(versionfile, name)
        versionfile.each_line do |l|
          return true if l =~ /set ModulesVersion "#{name}"/
        end
        false
      end

      def denormalized
        {}.tap do |h|
          c = 0
          root.each do |l|
            next unless l.has_content?
            # read the full path from the content
            components = []
            if (components = path_components(l.content.modulefile)).nil?
              # If no path is available default to using the current
              # path information and fill-out with 'undefN'
              components = [l.name]
              l.parentage.each do |parent|
                components.unshift(parent.name) unless parent.is_root?
              end
              # skip known top-levels
              unless components[0] == 'null'
                4.downto(components.length) { components << "undef#{c+=1}" }
              end
            end
            h[components] = l.content
          end
        end
      end

      def renormalize!
        #denormalize!
        #normalize!
        set_defaults!
      end

      def set_defaults!
        root.each_leaf do |node|
          node.content.default = true if node.breadth == 1
        end
      end

      def normalize!(node = root)
        node.children.dup.each do |c|
          normalize!(c)
        end
        if node.is_leaf?
          node.remove_from_parent! if !node.has_content?
        elsif node.level > 2 && node.out_degree == 1
          r = node.remove!(node.children.first)
          if r.is_leaf?
            node.content = r.content
          else
            r.children.each do |c|
              node << c
            end
          end
        end
        node
      end

      def update_tree(components, content, node = root)
        name = components.shift
        node = (node[name] || node << Tree::TreeNode.new(name))
        if components.empty?
          node.content = content
        else
          update_tree(components, content, node)
        end
      end

      def denormalize!
        r = Tree::TreeNode.new('ROOT')
        denormalized.each do |components, content|
          update_tree(components, content, r)
        end
        self.root = r
      end

      def path_components(modulefile)
        return if modulefile.nil?
        components = nil
        modulefile.each_line do |l|
          #set     distpath   libs/eigen/3.0.5/gcc/default/dist
          #set     appdir     /Users/markt/gridware/pkg/libs/eigen/3.0.5/gcc/default/dist
          # use magic path comment or appdir declaration to
          # determine the fully qualified package name
          if l =~ /## path: (.*)/ || l =~ /set\s+appdir\s+#{Config.packages_dir}\/(\S*).*$/
            components = $1.split('/')
            break
          end
        end
        components
      end
    end
  end
end
