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
require 'alces/tools/logging'

module Alces
  module Packager
    module IoHandler
      THEMES = {
        'dark' => {
          prim: 'rgb_' + [64,136,184].map {|i| sprintf('%02x', i) }.join,
          sec1: 'rgb_' + [77,91,194].map {|i| sprintf('%02x', i) }.join,
          sec2: 'rgb_' + [255,206,78].map {|i| sprintf('%02x', i) }.join,
          mid: 'rgb_' + [140,0,140].map {|i| sprintf('%02x', i) }.join,
          comp: 'rgb_' + [255,177,78].map {|i| sprintf('%02x', i) }.join
        },
        'light' => {
          prim: 'rgb_' + [32,102,152].map {|i| sprintf('%02x', i) }.join,
          sec1: 'rgb_' + [45,59,162].map {|i| sprintf('%02x', i) }.join,
          sec2: 'rgb_' + [177,128,0].map {|i| sprintf('%02x', i) }.join,
          mid: 'rgb_' + [96,0,96].map {|i| sprintf('%02x', i) }.join,
          comp: 'rgb_' + [177,99,0].map {|i| sprintf('%02x', i) }.join
        },
        'standard' => {
          prim: 'rgb_' + [48,118,168].map {|i| sprintf('%02x', i) }.join,
          sec1: 'rgb_' + [77,91,194].map {|i| sprintf('%02x', i) }.join,
          sec2: 'rgb_' + [193,144,16].map {|i| sprintf('%02x', i) }.join,
          mid: 'rgb_' + [128,0,128].map {|i| sprintf('%02x', i) }.join,
          comp: 'rgb_' + [193,115,16].map {|i| sprintf('%02x', i) }.join
        }
      }

      class << self
        include Alces::Tools::Logging

        def utter(msg, &block)
          info(msg, &block)
          say(msg)
        end

        def say(msg)
          $terminal.say(msg)
        end

        def title(msg, &block)
          info(msg, &block)
          say("\n > #{msg.bright_blue}")
        end

        def warning(msg, &block)
          warn(msg, &block)
          say("#{"WARNING!".color(:yellow)} #{msg}")
        end

        def doing(msg, width = 12, &block)
          info(msg, &block)
          say(sprintf("    #{"%#{width}s".color(:cyan)} ... ",msg))
        end

        def confirm(msg, &block)
          info("Asking for confirmation for: '#{msg}'", &block)
          say(msg)
          $terminal.agree("\nProceed (Y/N)? ")
        rescue Interrupt
          say "\nRequest cancelled by user."
          false
        end

        def tty?
          stream.tty?
          #STDOUT.tty? && STDERR.tty?
        end

        def stream
          ($terminal.instance_variable_get :@output)
        end

        def colored_path(p)
          case p
          when Metadata
            "#{p.repo.name.color(color(:sec1))}/#{p.type.color(color(:mid))}/#{p.name.color(color(:comp))}".tap do |s|
              s << "/#{p.version.color(color(:prim))}" unless p.version.blank?
            end
          when Package
            "#{p.type.color(color(:mid))}/#{p.name.color(color(:comp))}/#{p.version.color(color(:prim))}".tap do |s|
              s << "/#{p.tag.color(color(:sec1))}" unless p.tag.blank?
            end
          when String
            parts, vers = p.split(' ',2)
            parts = parts.split('/')
            "#{parts[0].color(color(:mid))}".tap do |s|
              if parts.length > 1
                s << '/' << parts[1].color(color(:comp))
              end
              if parts.length > 2
                s << '/' << parts[2].color(color(:prim))
              end
              if parts.length > 3
                3.upto(parts.length-1) do |n|
                  s << '/' << parts[n].color(:white)
                end
              end
              if vers
                s << ' ' << vers.color(color(:prim))
              end
            end
          else
            p
          end
        end

        def with_spinner(&block)
          if !tty?
            block.call
          else
            begin
              stream.print ' '
              spinner = Thread.new do
                spin = '|/-\\'
                i = 0
                loop do
                  stream.print "\b#{spin[i]}"
                  sleep 0.2
                  i = 0 if (i += 1) == 4
                end
              end
              block.call
            ensure
              spinner.kill
              stream.print "\b \b"
            end
          end
        end

        def color(c)
          theme[c]
        end

        def theme
          @theme ||= begin
                       theme = ENV['cw_SETTINGS_theme']
                       THEMES.key?(theme) ? THEMES[theme] : THEMES['standard']
                     end
        end
      end
    end
  end
end
