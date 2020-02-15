require "bundler/setup"
require "scopedog"
require 'forwardable' # HACK: supress NameError in rspec-cheki
require 'rspec/cheki'

Dir[File.expand_path(File.join('..', 'support', '**', '*.rb'), __FILE__)].each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
