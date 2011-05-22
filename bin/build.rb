#!/usr/bin/env ruby

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

if ARGV.length < 1
  puts %{
  sudo #{$0} [-v] {target_dir}

  builds a chroot directory.
  }
  exit 0
end

require File.join(File.dirname(__FILE__), '../lib/brig/builder')

def find_arg(key)
  i = ARGV.index(key)
  i ? ARGV[i + 1] : nil
end


target_dir = ARGV.last
verbose = (ARGV & %w[ -v --verbose ]).length > 0
ruby_src = find_arg('--rs')

Brig.build_chroot(
  target_dir,
  :verbose => verbose,
  :ruby_src => ruby_src)

