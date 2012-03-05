require 'multi_json'
require 'yaml'

module BugFlow
  class MissingController
    def method_missing(*args, &block)
    end
  end

  class Payload
    include BugFlow::Serializer
    
    attr_reader :exception
    attr_reader :location
    attr_reader :environment
    attr_reader :framework
    attr_reader :version
    attr_reader :extra_params
    
    # Initialize a new BugFlow::Payload object
    #   exception    => Exception object instance
    #   env          => Environment hash
    #   extra_params => Additional parameters
    # 
    def initialize(location, exception, env, extra_params={})
      @exception = {
        :class_name => exception.class.to_s,
        :message    => exception.message,
        :backtrace  => exception.backtrace,
        :timestamp  => Time.now
      }
      
      if location && !location.empty?
        @location = location
      elsif defined?(Rails)
        @kontroller  = env['action_controller.instance'] || BugFlow::MissingController.new
        @location = [@kontroller.controller_name, @kontroller.action_name].compact.join("#")
        @location = "undefined" if @location.empty?
      else
        @location = "undefined"
      end
      @environment  = clean_non_serializable_data(env)
      @version      = BugFlow::VERSION
      @framework    = 'rack'
      @framework    = 'rails'   if defined?(Rails)
      @framework    = 'sinatra' if defined?(Sinatra)

      @extra_params = extra_params.kind_of?(Hash) ? extra_params : {}
    end
    
    # Returns HASH representation of payload
    def to_hash
      {
        :exception   => @exception,
        :environment => @environment,
        :version     => @version,
        :framework   => @framework,
        :location    => @location
      }
    end
    
    # Returns JSON representation of payload
    #
    def to_json
      @extra_params.delete(:crash)
      @extra_params.delete('crash')
      MultiJson.encode({:crash => self.to_hash}.merge(@extra_params))
    end
    
    # Returns YAML representation of payload
    # 
    def to_yaml
      YAML.dump({:crash => self.to_hash})
    end
    
    # Returns XML representation of payload
    # 
    def to_xml
      # Not Implemented Yet
    end
  end
end
