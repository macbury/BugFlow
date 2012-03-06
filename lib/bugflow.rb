require 'bugflow/version'
require 'bugflow/errors'
require 'bugflow/sync'
require 'bugflow/configuration'
require 'bugflow/middleware'
require 'bugflow/request'
require 'bugflow/serializer'
require 'bugflow/payload'
require 'bugflow/crash'
require 'bugflow/delayed_job'
require 'bugflow/railtie'
module BugFlow
  # Set global configuration
  # 
  def self.configure(options)
    @@config = BugFlow::Configuration.new(options)
    BugFlow.start!
    @@config
  end
  
  def self.config
    @@config
  end
  # Manually sent notification
  #   location => string 
  #   exception => Exception object
  #   env       => Environment hash
  #
  def self.notify(location, exception, env)
    if @@config.nil?
      raise BugFlow::ConfigurationError, "No configuration were provided."
    end
    BugFlow::Crash.new(location, exception, env)
  end
end
