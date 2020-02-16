require "scopedog/version"

module Scopedog
  class Error < StandardError; end

  def self.logger
    @logger ||= ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
  end

  def self.logger=(logger)
    @logger = logger
  end
end

require "yard"
require "scopedog/directives"
require "scopedog/record_class"
require "scopedog/exporters/markdown_exporter"

begin
  require "scopedog/railtie"
rescue LoadError
  # no-op
end
