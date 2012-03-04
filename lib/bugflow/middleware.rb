module BugFlow
  class Middleware
    attr_reader :config
    
    def initialize(app, options={})
      @app = app
      @config = BugFlow.configure(options)
      BugFlow.start!(@config)
    end
    
    def call(env)
      begin
        @app.call(env)
      rescue Exception => exception
        BugFlow::Crash.new(@config, exception, env) unless @config.ignore_exception?(exception.class.to_s)
        raise exception
      end
      
    end
  end
end