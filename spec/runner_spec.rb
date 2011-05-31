
require 'spec_helper'


describe Brig::Runner do

  it 'flips burgers'
end

describe Brig do

  before(:all) do
    build_brig
  end
  after(:all) do
    nuke_brig
  end

  describe '.exec' do

    it 'returns the stdout and stderr for a give command' do

      stdout, stderr = Brig.exec('id', :chroot => 'spec_target')

      stderr.should == ''

      if Brig.uname == 'Darwin'
        stdout.should match(/\(nobody\)/)
      else
        stdout.should match(/\(brig\)/)
      end
    end
  end

  describe '.run' do

    it 'flips burgers'
  end

  describe '.eval' do

    it 'receives ruby code and returns the result as a string' do

      out = Brig.eval(':hello', :chroot => 'spec_target')

      out.chomp.should == 'hello'
    end

    it 'receives ruby code and returns the result as JSON' do

      out = Brig.eval('[ 1, 2, 3 ]', :chroot => 'spec_target')

      out.should == [ 1, 2, 3 ]
    end

    it 'raises an EvalError when failing' do

      err = begin
        Brig.eval('do_fail', :chroot => 'spec_target')
      rescue => e
        err = e
      end

      err.class.should == Brig::Runner::EvalError
      err.code.should == 'do_fail'
      err.stderr.should match(/undefined local variable/)
    end
  end
end

