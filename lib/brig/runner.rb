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

require 'open3'
require 'thread'
require 'rufus-json/automatic'


module Brig

  def self.exec(command, opts={}, &block)

    Brig::Runner.new(opts.merge(:pool => false)).exec(command, &block)
  end

  def self.run(ruby_code, opts={}, &block)

    Brig::Runner.new(opts.merge(:pool => false)).run(ruby_code, &block)
  end

  def self.eval(ruby_code, opts={})

    Brig::Runner.new(opts.merge(:pool => false)).eval(ruby_code)
  end

  class Runner

    def initialize(opts)

      @opts = opts

      if defined?(EM) and EM.reactor_running?
        require 'right_popen'
        class << self
          alias :popen :right_popen
        end
      end

      @pool = @opts[:pool] ? Queue.new : nil
    end

    def exec(command, stdin=nil, &block)

      root = determine_chroot

      com = if Brig.uname == 'Darwin'
        [ 'sudo', 'chroot', '-u', 'nobody', root,
          '/brig_scripts/runner.sh', determine_limits, command ]
      else
        [ 'sudo', 'chroot', root, 'su', '-', 'brig', '-c',
          "/brig_scripts/runner.sh \"#{determine_limits}\" #{command}" ]
      end

      popen(com, stdin) do |out, err|
        block.call(out, err)
        FileUtils.remove_dir(root, :force => false) if @opts[:chroot_original]
      end
    end

    def run(ruby_code, &block)

      do_run(ruby_code, false, &block)
    end

    def eval(ruby_code)

      do_run(ruby_code, true) do |stdout, stderr|

        if stderr != ''
          @opts[:on_failure].call(stderr, ruby_code)
        else
          @opts[:on_success].call(Rufus::Json.load(stdout))
        end
      end
    end

    protected

    def reload

      batch_size = @opts[:batch_size] || 20

      suf =  "_#{self.object_id}_#{$$}_#{Thread.current.object_id}"

      batch_size.times do |i|
        @pool << :reload if i == (batch_size * 0.6).to_i
        @pool << Brig.copy(@opts[:chroot_original], "#{suf}__#{i}")
      end
    end

    def unpooled_chroot

      Brig.copy(
        @opts[:chroot_original],
        "_#{self.object_id}_#{$$}_#{Thread.current.object_id}")
    end

    def determine_chroot

      return @opts[:chroot] || 'target' unless @opts[:chroot_original]
      return unpooled_chroot unless @pool

      root = @pool.pop

      if root == nil
        Thread.new { reload }
        root = unpooled_chroot
      elsif root == :reload
        Thread.new { reload }
        root = determine_chroot
      end

      root
    end

    def determine_limits

      return '' if @opts[:nolimits]

      mem = @opts[:ulimit_m] || 512
      fds = @opts[:ulimit_n] || 256
      dsk = @opts[:ulimit_f] || 1024 * 1024 * 2 # 512b blocks
      vme = @opts[:ulimit_v] || 3000000
      pup = @opts[:ulimit_u] || 512

      limits = [
        "ulimit -n #{fds}",
        "ulimit -m #{mem}",
        "ulimit -f #{dsk}",
        "ulimit -u #{pup}",
        'umask 077'
      ]

      if Brig.uname == 'Linux'
        limits << "ulimit -v #{vme}"
      end

      limits.join('|')
    end

    def do_run(ruby_code, json, &block)

      exec(json ? '_ruby_eval_' : '_ruby_run_', ruby_code, &block)
    end

    # The plain popen method. Uses Open3.
    #
    def popen(command, stdin, &block)

      Open3.popen3(*command) do |si, so, se, wt|

        si.write(stdin) if stdin
        si.flush
        si.close

        stdout = so.read
        stderr = se.read

        block.call(stdout, stderr)
      end
    end

    #
    # The right_popen callbacks go here
    #
    class RightTarget

      def initialize(exit_block)
        @exit_block = exit_block
        @stdout = ''
        @stderr = ''
      end

      def on_out(data)
        @stdout << data
      end

      def on_err(data)
        @stderr << data
      end

      def on_exit(status)
        @exit_block.call(@stdout, @stderr)
      end
    end

    # The right_popen method, will be used instead of the plain #popen
    # if EM is detected and has a reactor running.
    #
    def right_popen(command, stdin, &block)

      RightScale.popen3(
        :command => command,
        :target => RightTarget.new(block),
        :stdout_handler => :on_out,
        :stderr_handler => :on_err,
        :exit_handler => :on_exit,
        :input => stdin)
    end
  end
end

