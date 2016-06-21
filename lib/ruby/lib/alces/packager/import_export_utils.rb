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
    module ImportExportUtils
      def text_file?(file)
        run(['file',file]) do |r|
          r.success? && r.stdout.include?("text")
        end
      end

      def elf_file?(file)
        run(['file',file]) do |r|
          r.success? && r.stdout.include?("ELF")
        end
      end

      def patch_binary(f, old_str, new_str)
        old_hex = hex_for(old_str)
        new_hex = hex_for(new_str)
        if new_hex.length < old_hex.length
          new_hex << '0' * (old_hex.length - new_hex.length)
        elsif new_hex.length > old_hex.length
          raise "Unable to perform binary patch with longer string!"
        end
        hex_data = IO.popen("hexdump -ve '1/1 \"%.2X\"' #{f}") do |io|
          io.read
        end
        hex_data.gsub!(old_hex, new_hex)
        IO.popen("#{ENV['cw_ROOT']}/opt/xxd/bin/xxd -r -p", "rb+") do |io|
          res = "".force_encoding(Encoding::ASCII_8BIT)
          c = 0
          hex_data.each_char do |b|
            c += 1
            buf = "".force_encoding(Encoding::ASCII_8BIT)
            io.write b
            if io.read_nonblock(1, buf, exception: false) != :wait_readable
              res << buf
            end
          end
          io.close_write
          res << io.read
          out_file = "#{f}.clusterware.new"
          output = File.open(out_file, 'wb')
          output.write(res)
          output.close
          stat = File.stat(f)
          File.chmod(stat.mode, out_file)
          File.chown(stat.uid, stat.gid, out_file)
          File.rename(out_file, f)
        end
      end

      def hex_for(s)
        IO.popen("#{ENV['cw_ROOT']}/opt/xxd/bin/xxd -g 0 -u -ps -c 256", "r+") do |io|
          io.print(s)
          io.close_write
          io.read
        end.split("\n").join
      end
    end
  end
end
