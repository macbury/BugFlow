
module BugFlow
  class Crash
    def initialize(location, exception=nil, env={})
      unless config.kind_of?(BugFlow::Configuration)
        raise ArgumentError, "BugFlow::Configuration required!"
      end
      
      raise ArgumentError, "Exception required!" if exception.nil?
      raise ArgumentError, "Environment required!" if env.nil?
      
      @config = Bugflow.config
      @payload = BugFlow::Payload.new(location, exception, env, @config.extra_params)
      BugFlow.push(self) unless @config.ignore_exception?(exception.class.to_s)
    end
    
    def payload
      @payload
    end
  end
end
