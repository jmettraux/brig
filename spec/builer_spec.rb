
require 'spec_helper'


describe Brig::Builder do

  describe '.default_model' do

    it 'returns lib/brig/model.txt' do

      Brig::Builder.default_model.should ==
        File.read(File.join(File.dirname(__FILE__), '../lib/brig/model.txt'))
    end
  end
end

