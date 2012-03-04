
module BugFlow
  class Crash
    def initialize(config, exception=nil, env={})
      unless config.kind_of?(BugFlow::Configuration)
        raise ArgumentError, "BugFlow::Configuration required!"
      end
      
      raise ArgumentError, "Exception required!" if exception.nil?
      raise ArgumentError, "Environment required!" if env.nil?
      
      @config = config
      @payload = BugFlow::Payload.new(exception, env, @config.extra_params)
      BugFlow.push(self)
    end
    
    def payload
      @payload
    end
  end
end
