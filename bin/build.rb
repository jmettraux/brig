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



def puts_usage
  puts %{
  sudo #{$0} --show

    shows the default model used to build the chroot environment

  sudo #{$0} [-v] {target_dir}

    builds a chroot directory with the default model

  sudo #{$0} [-v] -i /ruby/bin/ruby -i /ruby/lib/ {target_dir}

    builds a chroot directory with the default model but adds one or
    more -i items (here Ruby and its libraries)
  }
end

if ARGV.length < 1
  puts_usage
  exit(0)
end

require File.join(File.dirname(__FILE__), '../lib/brig/builder')

#def find_arg(key)
#  i = ARGV.index(key)
#  i ? ARGV[i + 1] : nil
#end

if ARGV.include?('--show')
  puts Brig::Builder.default_model
  exit(0)
end

verbose = false
items = []
model = nil
target_dir = nil

while arg = ARGV.shift
  case arg
    when '-v', '--verbose' then verbose = true
    when '-m', '--model' then model = ARGV.shift
    when '-i' then items << ARGV.shift
    else target_dir = arg
  end
end

if target_dir == nil
  puts %{
** missing a target dir
  }
  puts_usage
  exit(1)
end

Brig::Builder.build(
  target_dir,
  :verbose => verbose,
  :model => model,
  :items => items)

