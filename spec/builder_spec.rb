
require 'spec_helper'


describe Brig::Builder do

  describe '.default_model' do

    it 'returns lib/brig/model.txt' do

      Brig::Builder.default_model.should ==
        File.read(File.join(File.dirname(__FILE__), '../lib/brig/model.txt'))
    end
  end
end

describe Brig do

  describe '.build' do

    after(:each) do
      nuke_brig
    end

    it 'builds a chroot place' do

      Brig.build('spec_target')

      File.exist?('spec_target').should == true
      File.directory?('spec_target').should == true
    end
  end
end
