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
require 'alces/tools/logging'
require 'alces/tools/config'
require 'alces/packager/metadata'
require 'alces/git'

module Alces
  module Packager
    class Repository < Struct.new(:path)
      class InvalidRepo < StandardError; end
        
      DEFAULT_CONFIG = {
        repo_paths: ['/opt/clusterware/installer/local/'],
      }

      class << self
        include Enumerable

        def config
          @config ||= DEFAULT_CONFIG.dup.tap do |h|
            cfgfile = Alces::Tools::Config.find("gridware.#{ENV['cw_DIST']}", false) ||
                      Alces::Tools::Config.find("gridware", false)
            h.merge!(YAML.load_file(cfgfile)) unless cfgfile.nil?
          end
        end
        
        def method_missing(s,*a,&b)
          if config.has_key?(s)
            config[s]
          else
            super
          end
        end

        def each(&block)
          all.each(&block)
        end
        
        def [](k)
          all[k]
        end

        def exists?(k)
          all.key?(k)
        end

        def all
          @all ||= repo_paths.map { |path| new(path) }
        end
      end
      
      include Alces::Tools::Logging
      
      attr_accessor :package_path

      def initialize(path)
        self.path = File.expand_path(path)
        self.package_path = File.join(self.path,'pkg')
      end

      def metadata
        @metadata ||= load_metadata
      end

      def name
        @name ||= File.basename(path)
      end

      def empty?
        !File.directory?(path) || packages.empty?
      end

      def descriptor
        if metadata.key?(:source)
          "git+#{metadata[:source]}@#{head_revision}"
        else
          "file:#{path}"
        end
      end

      def packages
        @packages ||= load_packages
      end

      def update!
        if metadata.key?(:source)
          r = Alces.git.sync(package_path, metadata[:source])
          case r
          when /^Branch master set up/, /^Updating/
            # force reload of packages if needed
            @packages = nil
            :ok
          when /^Already up-to-date./
            :uptodate
          else
            raise "Unrecognized response from synchronization: #{r.chomp}"
          end
        else
          :not_updateable
        end
      rescue
        raise "Unable to sync repo: '#{name}' (#{$!.message})"
      end

      private
      def head_revision
        Alces.git.head_revision(package_path)[0..6] rescue 'unknown'
      end

      def load_packages
        info "Loading repo from path: #{path}"
        if File.directory?(package_path)
          Dir[File.join(package_path,'**','metadata.yml')].map do |f|
            begin
              if (parts = f.gsub(package_path,'').split('/')).length > 4
                name, version = parts[-3..-2]
              else
                name = parts[-2]
                version = nil
              end
              yaml = File.read(f, encoding: 'utf-8')
              metadata = YAML.load(yaml)
              checksum = Digest::MD5.hexdigest(yaml)
              Metadata.new(name, version, metadata, checksum, self)
            rescue Psych::SyntaxError
              raise "Unable to parse: #{f} (#{$!.class.name}: #{$!.message})"
            rescue
              raise "Unable to parse: #{f} (#{$!.class.name}: #{$!.message})"
            end
          end
        else
          []
        end
      end

      def load_metadata
        if File.exists?("#{path}/repo.yml")
          YAML.load_file("#{path}/repo.yml")
        else
          {}
        end
      end
    end
  end
end
