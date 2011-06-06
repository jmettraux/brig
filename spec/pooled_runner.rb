
require 'spec_helper'


describe Brig::Runner do

  before(:all) do
    build_brig
  end
  after(:all) do
    nuke_brig
  end

  context 'when pooling' do

    it 'runs in a copy of the :chroot_original' do

      stdout = nil

      Brig.exec(
        'cat /BRIG.txt /THIS_BRIG.txt', :chroot_original => 'spec_target'
      ) do |out, err|
        stdout = out.strip
      end

      stdout.should match(/^spec_target\nspec_target_/)
    end

    it 'nukes the copy after usage' do

      stdout = nil

      Brig.exec(
        'cat /THIS_BRIG.txt', :chroot_original => 'spec_target'
      ) do |out, err|
        stdout = out.strip
      end

      File.exist?(stdout).should == false
    end

    context 'without a pool' do

      it 'flips burgers'
    end

    context 'with a pool' do

      it 'flips burgers'
    end
  end
end

