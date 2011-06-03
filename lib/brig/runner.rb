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
require 'rufus-json/automatic'


module Brig

  def self.exec(command, opts={})

    Brig::Runner.new(opts).exec(command)
  end

  def self.run(ruby_code, opts={})

    Brig::Runner.new(opts).run(ruby_code)
  end

  def self.eval(ruby_code, opts={})

    Brig::Runner.new(opts).eval(ruby_code)
  end

  DARWIN_USERNAME = 'nobody'

  class Runner

    class EvalError < RuntimeError

      attr_reader :code
      attr_reader :stderr

      def initialize(code, stderr)
        @code = code
        @stderr = stderr
        super('eval failed')
      end
    end

    def initialize(opts)

      @opts = opts
    end

    def exec(command, stdin=nil)

      chroot = @opts[:chroot] || 'target'

      com = if Brig.uname == 'Darwin'
        [ 'sudo', 'chroot', '-u', DARWIN_USERNAME, chroot ] + command
      else
        command = Array(command).join(' ')
        [ 'sudo', 'chroot', chroot, 'su', '-', 'brig', '-c', command ]
      end

      popen(com, stdin)
    end

    RUBY_EXE = '/brig_ruby/bin/ruby'

    def run(ruby_code)

      # TODO : unhardcode ruby path

      exec([
        RUBY_EXE, '-e', '"eval(STDIN.read)"'
      ], ruby_code)
    end

    def eval(ruby_code)

      # TODO : unhardcode ruby path

      sout, serr = exec([
        RUBY_EXE,
        '-e',
        "\"require 'rufus-json/automatic'; " +
        "puts Rufus::Json.dump(eval(STDIN.read))\""
      ], ruby_code)

      raise EvalError.new(ruby_code, serr) if serr != ''

      Rufus::Json.load(sout)
    end

    protected

    def popen(command, stdin=nil)

      # TODO if right_popen is present, use it

      sout, serr = nil

      Open3.popen3(*command) do |si, so, se, wt|
        si.write(stdin) if stdin
        si.flush
        si.close
        sout = so.read
        serr = se.read
      end

      [ sout, serr ]
    end
  end
end

