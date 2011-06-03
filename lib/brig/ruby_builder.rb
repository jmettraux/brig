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


module Brig

  def self.build_ruby(opts={})

    RubyBuilder.new.build(opts)
  end

  class RubyBuilder

    include BuilderHelper

    TMP_DIR = '/tmp/brig_ruby'

    def build(opts)

      start = Time.now

      raise(
        "cannot build ruby when not root, please sudo"
      ) unless `id`.match(/^uid=0\(root\)/)

      @version = opts[:version] || '1.9.2-p180'
      @verbose = opts[:verbose]
      @gems = (%w[ yajl-ruby rufus-json ] + (opts[:gems] || [])).join(' ')
      @target_dir = opts[:target_dir] || '/brig_ruby'

      if opts[:override]
        tell "r. overriding \n    #{@target_dir}"
        FileUtils.rm_rf(@target_dir) rescue nil
      elsif File.exist?(@target_dir)
        tell "r. ruby already present \n    #{@target_dir}"
        return
      end

      FileUtils.mkdir(TMP_DIR) rescue nil

      arc = locate_archive || download_archive

      raise("couldn't find ruby archive for #{@version}") unless arc

      tell "r. found ruby archive at \n    #{arc}"

      FileUtils.cp(arc, TMP_DIR) rescue nil

      farc = File.basename(arc)

      if arc.match(/\.bz2$/)
        `cd #{TMP_DIR} && tar xjvf #{farc} 2>&1`
      else
        `cd #{TMP_DIR} && tar xzvf #{farc} 2>&1`
      end

      src_dir = File.join(TMP_DIR, "ruby-#{@version}")

      tell "r. extracted ruby source to \n    #{src_dir}"

      conf_opts = "--prefix=#{@target_dir} --disable-install-doc"

      `cd #{src_dir} && ./configure #{conf_opts}`

      tell "r. configured with \n    #{conf_opts}"

      `(cd #{src_dir} && make && make install) 2>&1`

      tell "r. built ruby to \n    #{@target_dir}"

      `#{File.join(@target_dir, 'bin/gem')} install #{@gems}`

      tell "r. installed gems \n    #{@gems}"

      tell "r. ruby install done"
      tell "    weighs " + `du -sh #{@target_dir}`.strip.split(' ').first
      tell "    took #{Time.now - start}s"
    end

    protected

    def locate_archive

      arc = File.join(ENV['HOME'], ".rvm/archives/ruby-#{@version}")

      %w[ .tar.bz2 .tar.gz ].each do |suffix|
        fname = arc + suffix
        return fname if File.exist?(fname)
      end

      nil # not found
    end

    def download_archive

      fname = "ruby-#{@version}.tar.gz"
      target = File.join(TMP_DIR, fname)

      if File.exist?(target)

        tell ". already downloaded at \n    #{target}"

      else

        start = Time.now
        `curl -s http://ftp.ruby-lang.org/pub/ruby/1.9/#{fname} -o #{target}`

        tell ". downloaded in #{Time.now - start}s at \n    #{target}"
      end

      target
    end
  end
end

