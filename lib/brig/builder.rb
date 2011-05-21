#--
# Copyright (c) 2011-2011, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#++

require 'fileutils'


module Brig

  def self.tell(message)
    puts(message) if @verbose
  end

  def self.grep(file, regex)
    File.readlines(file).select { |l| regex.match(l) }.join("\n")
  end

  def self.split_ldd_output(out)
    out.split(/[\n\t \r]/).select { |e| e.match(/^\/.+[^:]$/) }
  end

  # TODO
  #
  def self.build_chroot(target_dir, opts={})

    @verbose = opts[:verbose]

    target_dir = File.expand_path(target_dir)

    FileUtils.mkdir(target_dir)

    %w[
      etc
      bin
      usr/bin
      usr/lib/system
    ].each do |dir|
      FileUtils.mkdir_p(File.join(target_dir, dir))
    end

    File.open(File.join(target_dir, 'etc/passwd'), 'wb') do |f|
      f.puts 'root:*:0:0:System Administrator:/var/root:/bin/sh'
    end
    File.open(File.join(target_dir, 'etc/group'), 'wb') do |f|
      #f.puts 'root:*:0:0:System Administrator:/var/root:/bin/sh'
    end

    apps = %w[
      /usr/lib/dyld
      bash
      ls mkdir mv pwd rm
      ruby
    ] + (opts[:apps] || [])

    ldd = 'otool -L' # OSX for now

    apps.each do |app|

      app = `which #{app}`.chomp unless app.match(/^\//)

      tell("app: #{app}")

      # copy the app to the jail

      FileUtils.cp(app, File.join(target_dir, app))

      # copy required libraries

      lddout = `#{ldd} #{app}`

      next if $? != 0 # program is ldd averse, let's go on

      split_ldd_output(lddout).each do |lib|

        FileUtils.cp(lib, File.join(target_dir, lib))
        tell("lib: #{lib}")

        split_ldd_output(`#{ldd} #{lib}`).each do |sublib|

          FileUtils.cp(sublib, File.join(target_dir, sublib))
          tell("sublib: #{sublib}")
        end
      end
    end
  end
end

