
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

    stdout.should == ''
    stderr.should_not == ''
  end

  it 'disallows su-ing for root via Ruby' do

    stdout, stderr = Brig.run('puts `(su - id) 2>&1`', :chroot => 'spec_target')

    stdout.strip.should == ''
    stderr.strip.should_not == ''
  end
end

