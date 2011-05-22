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

      @opts = opts
      @verbose = opts[:verbose]
      @target_dir = File.expand_path(target_dir)

      FileUtils.mkdir(@target_dir)
      FileUtils.mkdir_p(File.join(@target_dir, 'etc'))

      File.open(File.join(@target_dir, 'etc/passwd'), 'wb') do |f|
        f.puts 'root:*:0:0:System Administrator:/var/root:/bin/bash'
      end
      File.open(File.join(@target_dir, 'etc/group'), 'wb') do |f|
        #f.puts 'root:*:0:0:System Administrator:/var/root:/bin/sh'
      end

      # install apps

      apps = %w[ /usr/lib/dyld ]
      #apps += %w[ ls mkdir mv pwd rm cp chmod chown ]
      #apps += %w[ awk sed grep ]
      apps += %w[ which cat echo env bash ]
      apps += (opts[:apps] || [])

      apps.each do |app|

        app = `which #{app}`.chomp unless app.index('/')

        copy_app_or_lib(app)
      end

      # install ruby

      copy_ruby #if @opts[:ruby_src]

      # make sure executables are

      FileUtils.chmod(
        0755, File.join(@target_dir, 'usr/lib/dyld'), :verbose => @verbose)

      %w[
        bin sbin usr/bin usr/sbin
      ].each do |dir|
        Dir[File.join(@target_dir, dir, '*')].each do |path|
          FileUtils.chmod 0755, path, :verbose => @verbose
        end
      end
    end

    protected

    def tell(message)
      puts(message) if @verbose
    end

    def grep(file, regex)
      File.readlines(file).select { |l| regex.match(l) }.join("\n")
    end

    def copy_app_or_lib(app_or_lib, target=nil, depth=0)

      if depth == 0
        tell("app: #{app_or_lib}")
      else
        tell(("  " * depth) + "lib: " + app_or_lib)
      end

      cp(app_or_lib, target)

      ldd = 'otool -L' # OSX for now

      lddout = `#{ldd} #{app_or_lib}`

      return if $? != 0 # thing is ldd averse, let's go on

      @seen_libs ||= []

      libs = lddout.split(/[\n\t \r]/).select { |e| e.match(/^\/.+[^:]$/) }

      libs.each do |lib|

        next if @seen_libs.include?(lib)

        @seen_libs << lib

        copy_app_or_lib(lib, nil, depth + 1)
      end
    end

    def cp(source, target=nil)

      target = File.join(@target_dir, target || source)

      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.cp(source, target)

    #rescue Exception => e
    #  tell("      skipping\n        ..#{source}\n        ..#{e}")
    end

    def copy_ruby

      copy_app_or_lib('/ruby/bin/ruby')
      copy_app_or_lib('/ruby/bin/gem')

      lib_dir = File.join(@target_dir, 'ruby/lib/')
      FileUtils.mkdir_p(lib_dir)
      FileUtils.cp_r('/ruby/lib/.', lib_dir)

      libz_bundle = Dir['/ruby/**/zlib.bundle'].first
      copy_app_or_lib(libz_bundle)

      #libz = Dir['/Developer/**/libz.1.dylib'].first
      #FileUtils.cp(libz, File.join(@target_dir, 'usr/lib/'))
    end
  end
end

