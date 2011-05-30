
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

  describe '.eval' do

    it 'receives ruby code and returns the stdout as a string'
    it 'receives ruby code and parses the stdout as JSON if possible'
  end
end

