require "simplecov"
SimpleCov.start { add_filter("/vendor/bundle/") }

require "base64"
require "json"
require "pry"
require "pry-byebug"

ENV["PIPE_OPERATOR_FROZEN"] ||= "1"
require_relative "../lib/pipe_operator"

RSpec.configure do |config|
  config.filter_run :focus
  config.raise_errors_for_deprecations!
  config.run_all_when_everything_filtered = true
end
