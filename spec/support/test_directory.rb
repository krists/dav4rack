RSpec.configure do |config|
  config.before(:each) do
    FileUtils.mkdir(TEST_ROOT_DIRECTORY) unless File.exists?(TEST_ROOT_DIRECTORY)
  end

  config.after(:each) do
    FileUtils.rm_rf(TEST_ROOT_DIRECTORY) if File.exists?(TEST_ROOT_DIRECTORY)
  end
end
