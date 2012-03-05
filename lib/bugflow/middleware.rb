module BugFlow
  class Middleware
    attr_reader :config
    
    def initialize(app, options={})
      @app = app
    end
    
    def call(env)
      begin
        @app.call(env)
      rescue Exception => exception
        BugFlow.notify(nil, exception, env)
        raise exception
      end
      
    end
  end
end