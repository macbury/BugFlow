require 'bugflow/version'
require 'bugflow/errors'
require 'bugflow/sync'
require 'bugflow/configuration'
require 'bugflow/middleware'
require 'bugflow/request'
require 'bugflow/serializer'
require 'bugflow/payload'
require 'bugflow/crash'
module BugFlow
  # Set global configuration
  # 
  def self.configure(options)
    @@config = BugFlow::Configuration.new(options)
    @@config
  end
  
  # Manually sent notification
  #   exception => Exception object
  #   env       => Environment hash
  #
  def self.notify(exception, env)
    if @@config.nil?
      raise BugFlow::ConfigurationError, "No configuration were provided."
    end
    BugFlow::Crash.new(@@config, exception, env)
  end
end
