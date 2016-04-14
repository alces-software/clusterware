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
require 'alces/packager/depot_metadata'
require 'yaml'
require 'alces/git'

module Alces
  module Packager
    class DepotRepo < Struct.new(:path)
      class InvalidRepo < StandardError; end
      class << self
        include Enumerable

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
          @all ||= Config.depot_repo_paths.map { |path| new(path) }
        end

        def get(name)
          find {|r| r.name == name}
        end

        def get_depot(name)
          map {|r| r.depots.find {|d| d.name == name }}.first
        end
      end

      include Alces::Tools::Logging

      attr_accessor :metadata_path

      def initialize(path)
        self.path = File.expand_path(path)
        self.metadata_path = File.join(self.path,'data')
      end

      def metadata
        @metadata ||= load_metadata
      end

      def name
        @name ||= File.basename(path)
      end

      def depots
        @depot_metadata ||= load_depot_metadata
      end

      def update!
        if metadata.key?(:source)
          r = Alces.git.sync(metadata_path, metadata[:source])
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
      def load_depot_metadata
        info "Loading depot repo from path: #{path}"
        if File.directory?(path)
          Dir[File.join(path,'data','*.yml')].map do |f|
            begin
              yaml = File.read(f, encoding: 'utf-8')
              metadata = YAML.load(yaml)
              name = File.basename(f, '.yml')
              DepotMetadata.new(name, metadata)
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
