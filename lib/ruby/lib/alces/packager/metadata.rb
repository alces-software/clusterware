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

module Alces
  module Packager
    class Metadata < Struct.new(:name, :version, :metadata, :checksum, :repo)
      class << self
        def sort(arr)
          arr.sort do |a,b|
            begin
              Semver.new(a.semver) <=> Semver.new(b.semver)
            rescue
              a.semver <=> b.semver
            end
          end.sort do |a,b|
            File.join(a.repo.name, a.type, a.name) <=> File.join(b.repo.name, b.type, b.name)
          end
        end
      end
      
      include Alces::Tools::Logging
      
      attr_reader :mode
      
      def initialize(*)
        super
        @mode = metadata[:mode] || :installer
        self.version = "" if version.nil?
      end

      def path
        @path ||= "#{repo.name}/#{type}/#{name}".tap do |s|
          s << "/#{version}" unless version.empty?
        end
      end

      def method_missing(s,*a,&b)
        if metadata.has_key?(s)
          metadata[s]
        else
          super
        end
      end

      def validate!
        if type != 'ext'
          each_source do |src|
            f = source_file(src)
            raise NotFoundError, "Unable to locate a source file at '#{f}'" unless File.exists?(f) || File.exists?(source_fetch_file(src))
          end
        end
        patch_files.each do |p|
          raise NotFoundError, "Unable to locate a patch file at '#{p}'" unless File.exists?(p)
        end
        #        rescue
        #          raise "Validation error whilst checking package #{name}, error was [#{$!.message}]"
      end

      def <=>(b)
        path.downcase <=> b.path.downcase
      end

      def base_requirements(phase)
        requirements_from(metadata[:requirements], phase) || []
      end

      def compiler_requirements(compiler, phase)
        retrieve([]) do
          requirements_from(metadata[:compilers][compiler][:requirements], phase)
        end
      end

      def variant_requirements(variant, phase)
        retrieve([]) do
          requirements_from(metadata[:variants][variant][:requirements], phase)
        end
      end

      def retrieve(default, &block)
        ( block.call || default ) rescue default
      end

      def requirements(compiler, variant, phase)
        base_requirements(phase) +
          compiler_requirements(compiler, phase) + 
          variant_requirements(variant, phase)
      end

      def src_dir
        @src_dir ||= (metadata[:src_dir] || "#{name}-#{version}")
      end

      def file
        f = metadata[:src]
        if f.nil?
          nil
        elsif packaged_file?(f)
          packaged_file_path(f)
        else
          archive_file_path(f)
        end
      end

      def patch_files
        (metadata[:patches] || []).map { |p| source_file(p) }
      end

      def packaged_file_path(f)
        File.expand_path(File.join(repo.package_path,type,name,version,f))
      end

      def packaged_file?(f)
        File.exists?(packaged_file_path(f))
      end

      def source_file(f)
        if packaged_file?(f)
          packaged_file_path(f)
        else
          archive_file_path(f)
        end
      end

      def source_fetch_file(f)
        File.expand_path(File.join(repo.package_path,type,name,version,"#{f}.fetch"))
      end

      def source_md5sum_file(f)
        File.expand_path(File.join(repo.package_path,type,name,version,"#{f}.md5sum"))
      end

      def fetch_file
        source_file("#{src}.fetch")
      end

      def md5sum_file
        source_file("#{src}.md5sum")
      end

      def source_md5sum(f = md5sum_file)
        File.read(f).chomp if File.exists?(f)
      end

      def source_urls(f = fetch_file)
        File.exists?(f) ? File.read(f).split("\n") : []
      end

      def fallback_source_url
        fallback_url = (Config.fallback_package_url rescue nil) ||
          'https://s3-eu-west-1.amazonaws.com/packages.alces-software.com/gridware'
        "#{fallback_url}/#{name}/#{src}"
      end

      def archive_dir
        File.expand_path(File.join(Config.archives_dir,type,name,version))
      end

      def archive_file_path(f)
        File.join(archive_dir,f)
      end
      
      def validate_params!(params)
        if metadata[:params] && (missing_params = (metadata[:params].keys - params.keys)).any?
          raise InvalidParameterError, "No values specified for required parameters: #{missing_params.join(', ')}"
        end
      end

      def each_variant(&block)
        metadata[:variants].keys.compact.each { |variant| block.call(variant) }
      end

      def sources
        metadata[:sources] || []
      end

      def each_source(&block)
        sources.each(&block)
      end

      def date
        Date.strptime(metadata[:changelog].split("\n").first.strip, '* %a %b %e %Y')
      rescue
        'Unknown'
      end

      def help
        metadata[:help] || "Please refer to the website for further details on usage of this\npackage."
      end

      def license_help
        metadata[:license_help] || "Please refer to the website for further details regarding licensing."
      end

      def source_descriptor
        "#{type}/#{name}/#{version}@#{checksum[0..7]}"
      end

      def centred_summary
        centred(summary, fold: 60)
      end

      def title
        metadata[:title] || name
      end

      def top_title_bar
        centred("======== #{title} ========")
      end

      def bottom_title_bar
        centred("=" * (17 + title.length))
      end

      def semver
        @semver ||= (metadata[:semver] || Semver.mutate(version))
      end

      private
      def centred(text, opts = {})
        opts = {width: 70}.merge(opts)
        cmd = "sed -e :a -e 's/^.\\{1,#{opts[:width]-3}\\}$/ & /;ta'"
        cmd = "fold -s -w#{opts[:fold]} | #{cmd}" unless opts[:fold].nil?
        IO.popen(cmd,'w+') do |io| 
          io.puts text
          io.close_write
          io.read
        end.chomp
      end

      def requirements_from(o, phase = :build)
        case o
        when String
          [o]
        when Array
          o
        when Hash
          requirements_from(o[phase])
        when NilClass
          []
        else
          raise PackageError, "Invalid requirements definition type (#{o.class.name})"
        end
      end
    end
  end
end
