
require 'spec_helper'


describe 'a brig' do

  before(:all) do
    build_brig
  end
  after(:all) do
    nuke_brig
  end

  it 'flips burgers'
end

