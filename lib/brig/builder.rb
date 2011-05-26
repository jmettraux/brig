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

  class Builder

    def self.build_chroot(target_dir, opts={})

      Brig::Builder.new.build(target_dir, opts)
    end

    def self.default_model

      File.read(File.join(File.dirname(__FILE__), 'model.txt'))
    end

    def self.read_model(model_path)

      model = model_path ? File.read(model_path) : default_model

      model.split("\n").inject([]) { |a, line|
        if line.strip.match(/^[^#]/)
          a << line.split(/\s+/).select { |w| ! w.match(/^#/) }
        end
        a
      }
    end

    def build(target_dir, opts)

      start = Time.now

      @opts = opts
      @verbose = opts[:verbose]
      @target_dir = File.expand_path(target_dir)

      class << @target_dir
        def join(*args)
          args.unshift(self)
          File.join(*args)
        end
      end

      FileUtils.rm_rf(@target_dir)
      FileUtils.mkdir(@target_dir)

      FileUtils.mkdir_p(@target_dir.join('etc/'))
      FileUtils.mkdir_p(@target_dir.join('home/brig/'))

      File.open(@target_dir.join('etc/passwd'), 'wb') do |f|
        f.puts 'nobody:*:-2:-2:just a nobody:/home/brig:/bin/bash'
        #f.puts 'brig:*:9000:9000:Brig User:/home/brig:/bin/bash'
      end

      model = Builder.read_model(opts[:model])
      model += (opts[:items] || [])

      # adding indispensible apps

      if uname == 'Darwin'
        model.unshift([ '/usr/lib/dyld' ])
      else
        model.unshift([ 'ld' ])
      end

      model.unshift([ 'su' ])

      model.each do |item|

        pa = item.first
        optional = item.include?('?')

        path = pa.match(/^\//) ? pa : `which #{pa}`.chomp
        puts ". #{pa} -> #{path}" if @verbose

        next if optional and ( ! File.exist?(path))

        if pa.index('*')
          copy_pattern(pa)
        elsif File.directory?(path)
          copy_dir(path)
        else
          copy(path)
        end
      end

      if @verbose
        puts
        puts "success"
        puts "  #{`du -sh #{@target_dir}`}"
        puts "  took #{Time.now - start}s"
        puts "  copied #{@seen_libs.size} libs"
        puts
      end
    end

    protected

    def uname

      @uname ||= `uname`.chomp
    end

    def tell(message)

      puts(message) if @verbose
    end

    def copy_pattern(path)

      Dir[path].each { |pa| copy(pa) }
    end

    def copy_dir(path)

      # at first, copy the stuff cp -pR path

      FileUtils.cp_r(path, @target_dir.join(path), :preserve => true)

      tell("dir: #{path}")

      # then make sure that each lib in there has its dependencies
      # satisfied

      libs = if uname == 'Darwin'
        Dir[File.join(path, '**', '*.dylib')] +
        Dir[File.join(path, '**', '*.bundle')]
      else
        Dir[File.join(path, '**', '*.so')]
      end

      libs.each { |lib| copy(lib, 1) }
    end

    #def is_lib?(path)
    #  path.match(/^lib|\.bundle$|\.dylib$|\.so$/)
    #end

    def copy(app_or_lib, depth=0)

      return unless app_or_lib

      target = cp(app_or_lib)

      if depth == 0
        if File.executable?(app_or_lib)
          tell("  app: #{app_or_lib}")
        else
          tell("  file: #{app_or_lib}")
        end
      else
        tell(("  " * (depth + 1)) + "lib: " + app_or_lib)
      end

      ldd = (uname == 'Darwin') ? 'otool -L' : 'ldd'

      lddout = `#{ldd} #{app_or_lib}`

      return if $? != 0 # thing is ldd averse, let's go on

      @seen_libs ||= []

      libs = lddout.split(/[\n\t \r]/).select { |e| e.match(/^\/.+[^:]$/) }

      libs.each do |lib|

        next if @seen_libs.include?(lib)

        @seen_libs << lib

        copy(lib, depth + 1)
      end
    end

    def cp(source)

      target = @target_dir.join(source)

      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.cp(source, target, :preserve => true)

      target

    rescue Exception => e
      puts "** failed to copy #{source}"
      raise e
    end
  end
end

