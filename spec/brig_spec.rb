
require 'spec_helper'


describe 'a brig' do

  before(:all) do
    build_brig
  end
  after(:all) do
    nuke_brig
  end

  it 'disallows su-ing for root' do

    stdout, stderr = Brig.exec('su - id', :chroot => 'spec_target')

    stdout.strip.should == ''

    if Brig.uname == 'Darwin'
      stderr.should match(/su - id: No such file or directory/)
    else
      stderr.should match(/must be run from a terminal/)
    end
  end

  it 'disallows su-ing for root via Ruby' do

    stdout, stderr = Brig.run('puts `su - id`', :chroot => 'spec_target')

    stdout.strip.should == ''

    if Brig.uname == 'Darwin'
      stderr.should == ''
    else
      stderr.should match(/must be run from a terminal/)
    end
  end
end

