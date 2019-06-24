ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
Bundler.require(:default)
require "dav4rack"

TEST_ROOT_DIRECTORY = File.join(File.expand_path("..", __dir__), "tmp", "htdocs")

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

Dir[File.join(File.expand_path(".", __dir__), "support", "**", "*.rb")].each do |path|
  require path
end