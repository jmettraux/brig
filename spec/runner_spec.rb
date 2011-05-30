
require 'spec_helper'


describe Brig::Runner do

  describe '.exec' do

    it 'returns the stdout and stderr for a give command' do

      stdout, stderr = Brig.exec('ls')

      p stdout
    end
  end
end

describe Brig do

  before(:all) do
    build_ruby_brig
  end
  after(:all) do
    nuke_brig
  end

  describe '.eval' do

    it 'receives ruby code and returns the stdout as a string' do
    end

    it 'receives ruby code and parses the stdout as JSON if possible' do
    end
  end
end

