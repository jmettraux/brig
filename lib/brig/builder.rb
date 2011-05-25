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

      FileUtils.rm_rf(@target_dir)
      FileUtils.mkdir(@target_dir)
      FileUtils.mkdir_p(File.join(@target_dir, 'etc/'))
      FileUtils.mkdir_p(File.join(@target_dir, 'home/brig/'))

      # copy configuration files

      #File.open(File.join(@target_dir, 'etc/passwd'), 'wb') do |f|
      #  f.puts 'root:*:0:0:System Administrator:/var/root:/bin/bash'
      #  f.puts 'brig:*:1000:1000:Brig User:/home/brig:/bin/bash'
      #end
      #File.open(File.join(@target_dir, 'etc/group'), 'wb') do |f|
      #  f.puts 'brig:x:1000:'
      #end

      cp('/etc/hosts', @verbose)
      cp('/etc/host.conf', @verbose)
      cp('/etc/resolv.conf', @verbose)
      cp('/etc/nsswitch.conf', @verbose)

      # copy libs

      # libs for name resolution

      Dir['/lib/**/libns*'].each do |lib|
        copy_app_or_lib(lib)
      end
      Dir['/usr/lib/**/libns*'].each do |lib|
        copy_app_or_lib(lib)
      end
      Dir['/lib/**/libresolv*'].each do |lib|
        copy_app_or_lib(lib)
      end

      # libs for event machine

      Dir['/usr/lib/**/libstd*'].each do |lib|
        copy_app_or_lib(lib)
      end

      # install apps

      apps = []

      case uname
        when 'Linux'
          apps += %w[ ld ]
        when 'Darwin'
          apps += %w[ /usr/lib/dyld ]
      end

      #apps += %w[ ls mkdir mv pwd rm cp chmod chown ]
      #apps += %w[ awk sed grep ]
      apps += %w[ id ls which cat echo env bash ]
      apps += %w[ uuidgen ping host dig nslookup ]
      apps += %w[ curl strace ]

      apps.each do |app|
        app = `which #{app}`.chomp unless app.index('/')
        copy_app_or_lib(app)
      end

      copy_ruby if @opts[:ruby_prefix]
    end

    protected

    def uname

      @uname ||= `uname`.chomp
    end

    def tell(message)

      puts(message) if @verbose
    end

    def grep(file, regex)

      File.readlines(file).select { |l| regex.match(l) }.join("\n")
    end

    def copy_app_or_lib(app_or_lib, depth=0)

      return unless app_or_lib

      target = cp(app_or_lib)

      if depth == 0 and ( ! File.basename(app_or_lib).match(/^lib/))
        FileUtils.chmod(0755, target, :verbose => @verbose)
        tell("app: #{app_or_lib}")
      else
        tell(("  " * depth) + "lib: " + app_or_lib)
      end

      ldd = (uname == 'Darwin') ? 'otool -L' : 'ldd'

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

    def cp(source, verbose=false)

      target = File.join(@target_dir, source)

      FileUtils.mkdir_p(File.dirname(target))
      FileUtils.cp(source, target)

      tell("cp: #{source}") if verbose

      target
    end

    def copy_ruby

      ruby_prefix = @opts[:ruby_prefix]

      copy_app_or_lib(File.join(ruby_prefix, 'bin/ruby'))

      lib_dir = File.join(@target_dir, ruby_prefix, 'lib/')
      FileUtils.mkdir_p(lib_dir)
      FileUtils.cp_r(File.join(ruby_prefix, 'lib/.'), lib_dir)

      #copy_app_or_lib('/ruby/bin/gem')
        # don't let chroot install gems [too easily]

      %w[
        md5 openssl
      ].collect { |lib|
        lib + ((uname == 'Darwin') ? '.bundle' : '.so')
      }.each do |lib|
        lib = Dir[File.join(ruby_prefix, '**', lib)].first
        copy_app_or_lib(lib, 1)
      end
    end
  end
end

