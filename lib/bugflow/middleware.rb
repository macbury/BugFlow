module BugFlow
  class Middleware

    def initialize(app, options={})
      @app = app
      bind_notifications
    end
    
    def bind_notifications
      ActiveSupport::Notifications.subscribe /start_processing.action_controller/ do |name, start, finish, id, payload|
        BugFlow::Request.current_request.parse_payload(payload)
      end

      ActiveSupport::Notifications.subscribe /sql.active_record/ do |name, start, finish, id, payload|
        BugFlow::Request.current_request.queries << BugFlow::Query.new(start, finish, payload)
      end
    
      ActiveSupport::Notifications.subscribe /!render_template.action_view/ do |name, start, finish, id, payload|
        BugFlow::Request.current_request.views << BugFlow::View.new(start, finish, payload)
      end
    end

    def call(env)
      begin
        BugFlow::Request.start!(env)
        @app.call(env)
      rescue Exception => exception
        BugFlow::Request.finish!(exception)
        raise exception
      else
        BugFlow::Request.finish!
      end
      
    end
  end
end