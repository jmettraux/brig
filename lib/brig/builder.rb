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

  def self.build_chroot(target_dir, opts={})

    Brig::Builder.new.build_chroot(target_dir, opts)
  end

  class Builder

    def build_chroot(target_dir, opts)

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
        ls mkdir mv pwd rm cp cat
        awk sed grep which tar curl gunzip bunzip2
        which chmod chown
        bash
      ] + (opts[:apps] || [])

      apps.each do |app|

        app = `which #{app}`.chomp unless app.match(/^\//)

        tell("app: #{app}")

        # copy the app to the jail

        cp(app, target_dir)

        # copy required libraries

        copy_libs(app, target_dir)
      end
    end

    protected

    def tell(message)
      puts(message) if @verbose
    end

    def grep(file, regex)
      File.readlines(file).select { |l| regex.match(l) }.join("\n")
    end

    def copy_libs(app_or_lib, target_dir, depth=1)

      @seen_libs ||= []

      ldd = 'otool -L' # OSX for now

      lddout = `#{ldd} #{app_or_lib}`

      return if $? != 0 # program is ldd averse, let's go on

      libs = lddout.split(/[\n\t \r]/).select { |e| e.match(/^\/.+[^:]$/) }

      libs.each do |lib|

        next if @seen_libs.include?(lib)

        cp(lib, target_dir)

        tell(("  " * depth) + "lib: " + lib)

        @seen_libs << lib

        copy_libs(lib, target_dir, depth + 1)
      end
    end

    def cp(source, target_dir)

      target = File.join(target_dir, source)

      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.cp(source, target)

    #rescue Exception => e
    #  tell("      skipping\n        ..#{source}\n        ..#{e}")
    end
  end
end

