
require 'spec_helper'


describe Brig::Builder do

  describe '.default_model' do

    it 'returns lib/brig/model.txt' do

      Brig::Builder.default_model.should ==
        File.read(File.join(File.dirname(__FILE__), '../lib/brig/model.txt'))
    end
  end

  describe '.build' do

    after(:each) do

      FileUtils.rm_rf('spec_target')
    end

    it 'builds a chroot place' do

      Brig::Builder.build('spec_target')

      File.exist?('spec_target').should == true
      File.directory?('spec_target').should == true
    end
  end
end

