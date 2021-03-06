#!/bin/bash

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

#
# this file is a wrapper to execute calls in the chroot
#

RUBY=/brig_ruby/bin/ruby

# ulimit/umask

IFS='|'
for x in $1; do
  #echo ">$x<"
  eval $x
done
unset IFS
  #
  # the eval is necessary, without it bash believes umask/ulimit are
  # commands (and not shell builtins)

shift

# run/eval/exec

if [[ $1 == '_ruby_run_' ]]; then
  $RUBY -e "eval(STDIN.read)"
elif [[ $1 == '_ruby_eval_' ]]; then
  $RUBY -e "require 'rufus-json/automatic'; puts Rufus::Json.dump(eval(STDIN.read))"
else
  $*
fi

