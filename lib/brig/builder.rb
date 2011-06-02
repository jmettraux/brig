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

  def self.build(target_dir, opts={})

    Brig::Builder.new.build(target_dir, opts)
  end

  class Builder

    include BuilderHelper

    def self.default_template

      File.read(File.join(File.dirname(__FILE__), 'template.txt'))
    end

    def self.read_template(template_path)

      template = template_path ? File.read(template_path) : default_template

      template.split("\n").inject([]) { |a, line|
        if line.strip.match(/^[^#]/)
          a << line.split(/\s+/).select { |w| ! w.match(/^#/) }
        end
        a
      }
    end

    def build(target_dir, opts)

      raise(
        "cannot build ruby when not root, please sudo"
      ) unless `id`.match(/^uid=0\(root\)/)

      start = Time.now

      @opts = opts
      @verbose = opts[:verbose]
      @target_dir = File.expand_path(target_dir)
      @excluded = []

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

      #File.open(@target_dir.join('etc/passwd'), 'wb') do |f|
      #  f.puts 'brig:*:9000:9000:Brig User:/home/brig:/bin/bash'
      #end
      cp('/etc/passwd')
      cp('/etc/shadow') rescue nil

      template = Builder.read_template(opts[:template])
      template += (opts[:items] || [])

      # adding indispensible apps

      if Brig.uname == 'Darwin'
        template.unshift([ '/usr/lib/dyld' ])
      else
        template.unshift([ 'ld' ])
      end

      @excluded = template.inject([]) { |a, item|
        if item[0] == '!'
          pattern = item[1]
          pattern = Regexp.new(pattern[1..-2]) if pattern.match(/^\/.+\/$/)
          a << pattern
        end
        a
      }

      template.each do |item|

        pa = item.first
        optional = item.include?('?')

        next if pa == '!'

        path = pa.match(/^\//) ? pa : `which #{pa}`.chomp
        puts ". #{pa} -> #{path}" if @verbose

        next if optional and ( ! File.exist?(path))

        if pa.index('*')
          copy_pattern(pa)
        elsif File.directory?(path)
          copy_dir(path)
        else
          copy_app_or_lib(path)
        end
      end

      tell
      tell "success"
      tell "  #{`du -sh #{@target_dir}`}"
      tell "  took #{Time.now - start}s"
      tell "  copied #{@seen_libs.size} libs"
      tell
    end

    protected

    def copy_pattern(path)

      Dir[path].each { |pa| copy_app_or_lib(pa) }
    end

    def is_lib?(path)

      path.match(/^lib|\.bundle$|\.dylib$|\.so$|\.so2$/)
    end

    def copy_dir(path)

      #puts "..#{path}"

      FileUtils.mkdir_p(@target_dir.join(path))

      Dir.new(path).each do |pa|
        next if pa == '.' or pa == '..'
        pat = File.join(path, pa)
        if is_lib?(pat)
          copy_app_or_lib(pat, 1)
        elsif File.directory?(pat)
          copy_dir(pat)
        else
          cp(pat)
        end
      end
    end

    def copy_app_or_lib(app_or_lib, depth=0)

      return unless app_or_lib
      return if @excluded.find { |pat| app_or_lib.match(pat) }

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

      ldd = (Brig.uname == 'Darwin') ? 'otool -L' : 'ldd'

      lddout = `#{ldd} #{app_or_lib}`

      return if $? != 0 # thing is ldd averse, let's go on

      @seen_libs ||= []

      libs = lddout.split(/[\n\t \r]/).select { |e| e.match(/^\/.+[^:]$/) }

      libs.each do |lib|

        next if @seen_libs.include?(lib)

        @seen_libs << lib

        copy_app_or_lib(lib, depth + 1)
      end
    end

    def cp(source)

      target = @target_dir.join(source)

      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.cp(source, target, :preserve => true)

      target

    rescue Exception => e
      #puts "** failed to copy #{source}"
      raise e
    end
  end
end

