
require 'spec_helper'


describe Brig::Builder do

  describe '.default_model' do

    it 'returns lib/brig/template.txt' do

      Brig::Builder.default_template.should ==
        File.read(File.join(File.dirname(__FILE__), '../lib/brig/template.txt'))
    end
  end
end

describe Brig do

  describe '.build' do

    after(:each) do
      nuke_brig
    end

    it 'builds a chroot place' do

      #Brig.build('spec_target')
      build_brig # sudo : neeeeeed !

      File.exist?('spec_target').should == true
      File.directory?('spec_target').should == true
    end
  end
end

