
require 'spec_helper'


describe Brig::Runner do

  before(:all) do
    build_brig
  end
  after(:all) do
    nuke_brigs
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

      it 'runs in a oneshot copy' do

        id = nil

        Brig.exec(
          'cat /THIS_BRIG.txt', :chroot_original => 'spec_target'
        ) do |out, err|
          id = out.strip
        end

        id.should_not match(/__\d+$/)
      end
    end

    context 'with a pool' do

      before(:all) do
        @runner = Brig::Runner.new(:chroot_original => 'spec_target')
      end
      after(:all) do
        @runner.close
      end

      it 'prepares 20 copies in advance' do

        sleep 7

        @runner.instance_variable_get(:@pool).size.should be > 1
      end

      it 'runs each time in a different copy' do

        ids = []

        3.times do
          @runner.exec('cat /THIS_BRIG.txt') { |out, err| ids << out.strip }
        end

        ids.collect { |i| i.split('_').last.to_i }.should == [ 0, 1, 2 ]
      end
    end
  end
end

