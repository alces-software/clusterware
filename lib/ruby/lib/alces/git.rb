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
require 'grit'

module Alces
  module Git
    class << self
      Grit::Git.git_timeout = 30
      Grit::Git.git_binary = '/opt/clusterware/opt/git/bin/git'

      def native(repo, &block)
        Dir.chdir(repo.working_dir) do
          block.call(repo.git)
        end
      end

      def fetch(repo, remote)
        repo.remote_fetch(remote)
      end  

      def branch(repo, remote, branch)
        repo.refs.find { |r| r.name =~ /^#{remote}\/#{branch}$/ }.tap do |b|
          raise "Unable to find source for repo '#{repo.working_dir.split('/')[-2]}'" if b.nil?
        end
      end

      def head_revision(path)
        Grit::Repo.new(path).commits.first.id
      end

      def with_remote(repo, url, &block)
        remote = 'upstream'
        repo.remote_add(remote, url)
        block.call(repo, remote).tap do 
          native(repo) { |g| g.remote({}, 'rm', remote) }
        end
      end

      def checkout(repo, remote, branch)
        fetch(repo, remote)
        native(repo) { |g| g.checkout({b: 'master'}, branch(repo, remote, branch).name) }
      end

      def pull(repo, remote, branch)
        fetch(repo, remote)
        native(repo) { |g| g.merge({}, branch(repo, remote, branch).name) }
      end

      def sync(path, url, branch = 'master')
        if File.directory?(File.join(path,'.git'))
          if File.writable?(path)
            with_remote(Grit::Repo.new(path), url) do |repo, remote|
              pull(repo, remote, branch)
            end
          else
            raise "Permission denied for repository: '#{path.split('/')[-2]}'"
          end
        else
          with_remote(Grit::Repo.init(path), url) do |repo, remote|
            checkout(repo, remote, branch)
          end
        end
      end      
    end
  end

  class << self
    def git
      @git ||= Alces::Git
    end
  end
end

# Grit does not support Ruby 2.0 right now
class String
  if self.method_defined?(:ord)
    def getord(offset); self[offset].ord; end
  else
    alias :getord :[]
  end
end

Object.send(:remove_const,:PACK_IDX_SIGNATURE)
PACK_IDX_SIGNATURE = "\377tOc".b
