
require 'brig'
require 'eventmachine'


Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each do |f|
  require(f)
end

RSpec.configure do |config|

  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  config.include BrigHelper
end

