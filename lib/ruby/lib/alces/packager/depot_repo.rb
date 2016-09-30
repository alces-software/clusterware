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

        def requiring_update
          select do |repo|
            repo.last_update + Config.update_period < DateTime.now
          end
        end

        def get(name)
          find {|r| r.name == name}
        end

        def get_depot(name)
          map {|r| r.depots.find {|d| d.name == name }}.compact.first
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
          case r = Alces.git.sync(metadata_path, metadata[:source])
          when /^Branch master set up/
            set_last_update
            # force reload of depot metadata if needed
            @depot_metadata = nil
            [:ok, head_revision]
          when /^Updating (\S*)\.\.(\S*)/
            set_last_update
            cur = $1
            tgt = $2
            head_rev = head_revision
            if head_rev != tgt
              [:outofsync, head_rev]
            else
              # force reload of packages if needed
              @depot_metadata = nil
              [:ok, tgt]
            end
          when /^Already up-to-date./
            set_last_update
            [:uptodate, head_revision]
          else
            raise "Unrecognized response from synchronization: #{r.chomp}"
          end
        else
          set_last_update
          [:not_updateable, nil]
        end
      rescue
        raise "Unable to sync repo: '#{name}' (#{$!.message})"
      end

      def last_update
        if File.exists?(last_update_file)
          datetime_str = File.readlines(last_update_file).first
          DateTime.parse(datetime_str)
        else
          # Return earliest possible datetime so update will (probably) run
          # when next needed.
          DateTime.new
        end
      end

      def last_update=(datetime)
        File.open(last_update_file, 'w') do |file|
          file.write(datetime)
        end
      end

      private
      def head_revision
        Alces.git.head_revision(metadata_path)[0..6] rescue 'unknown'
      end

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

      def last_update_file
        File.join(path, Config.last_update_filename)
      end

      def set_last_update
        self.last_update = DateTime.now
      end
    end
  end
end
