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

        def find_definitions(a)
          map do |r|
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
                end
              end
            end
          end.flatten
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
          case Alces.git.sync(repo_path, metadata[:source])
          when /^Branch master set up/
            # force reload of packages if needed
            @packages = nil
            [:ok, head_revision]
          when /^Updating (\S*)\.\.(\S*)/
            cur = $1
            tgt = $2
            head_rev = head_revision
            if head_rev != tgt
              [:outofsync, head_rev]
            else
              # force reload of packages if needed
              @packages = nil
              [:ok, tgt]
            end
          when /^Already up-to-date./
            [:uptodate, head_revision]
          else
            raise "Unrecognized response from synchronization: #{r.chomp}"
          end
        else
          [:not_updateable, nil]
        end
      rescue
        raise "Unable to sync repo: '#{name}' (#{$!.message})"
      end

      private
      def repo_path
        @repo_path ||= metadata[:schema] == 1 ? package_path : path
      end

      def head_revision
        Alces.git.head_revision(repo_path)[0..6] rescue 'unknown'
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
