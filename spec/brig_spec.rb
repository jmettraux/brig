
require 'spec_helper'


describe 'a brig' do

  before(:all) do
    build_brig
  end
  after(:all) do
    nuke_brigs
  end

  it 'is tagged via BRIG.txt' do

    stdout, stderr = nil

    Brig.exec('cat /BRIG.txt', :chroot => 'spec_target') do |out, err|
      stdout, stderr = out, err
    end

    stderr.strip.should == ''
    stdout.strip.should == 'spec_target'
  end

  it 'is tagged via THIS_BRIG.txt' do

    stdout, stderr = nil

    Brig.exec('cat /THIS_BRIG.txt', :chroot => 'spec_target') do |out, err|
      stdout, stderr = out, err
    end

    stderr.strip.should == ''
    stdout.strip.should == 'spec_target'
  end

  it 'disallows su-ing for root' do

    stdout, stderr = nil

    Brig.exec('su - id', :chroot => 'spec_target') do |out, err|
      stdout, stderr = out, err
    end

    stdout.strip.should == ''

    if Brig.uname == 'Darwin'
      stderr.should match(/Segmentation fault/)
    else
      stderr.should match(/must be run from a terminal/)
    end
  end

  it 'disallows su-ing for root via Ruby' do

    stdout, stderr = nil

    Brig.run('puts `su - id`', :chroot => 'spec_target') do |out, err|
      stdout, stderr = out, err
    end

    stdout.strip.should == ''

    if Brig.uname == 'Darwin'
      stderr.should == ''
    else
      stderr.should match(/must be run from a terminal/)
    end
  end

  it 'enforces a 077 umask' do

    stdout, stderr = nil

    Brig.exec('umask', :chroot => 'spec_target') do |out, err|
      stdout, stderr = out, err
    end

    stderr.should == ''
    stdout.strip.should == '0077'
  end

  it 'enforces ulimit -u 512' do

    stdout, stderr = nil

    Brig.exec('ulimit -u', :chroot => 'spec_target') do |out, err|
      stdout, stderr = out, err
    end

    stderr.should == ''
    if Brig.uname == 'Darwin'
      stdout.strip.should == '266'
    else
      stdout.strip.should == '512'
    end
  end

  it 'sets no limits when :nolimits => true' do

    stdout, stderr = nil

    Brig.exec('umask', :chroot => 'spec_target', :nolimits => true) do |out, err|
      stdout, stderr = out, err
    end

    stderr.should == ''
    stdout.strip.should == '0022'
  end
end

