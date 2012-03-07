module BugFlow
  class Middleware

    def initialize(app, options={})
      @app = app
      bind_notifications
    end

    def bind_notifications
      ActiveSupport::Notifications.subscribe /start_processing.action_controller/ do |name, start, finish, id, payload|
        @request_monitor.parse_payload(payload)
      end

      ActiveSupport::Notifications.subscribe /sql.active_record/ do |name, start, finish, id, payload|
        @request_monitor.queries << BugFlow::Query.new(start, finish, payload) if @request_monitor 
      end
    
      ActiveSupport::Notifications.subscribe /!render_template.action_view/ do |name, start, finish, id, payload|
        @request_monitor.views << BugFlow::View.new(start, finish, payload) if @request_monitor
      end

      ActiveSupport::Notifications.subscribe "http.request" do |name, start, finish, id, payload|
        BugFlow.debug [name, start, finish, id, payload].inspect
      end

      ActiveSupport::Notifications.subscribe "process_action.action_controller" do
        @request_monitor.finish!
      end

      bind_http_notifications
    end

    def bind_http_notifications
      Net::HTTP.class_eval do
        def request_with_bugflow(*args, &block)
          resp = nil
          ActiveSupport::Notifications.instrument("http.request", :search => search) do |payload|
            resp = request_without_bugflow(*args, &block)
            payload = { :host => @address }
          end
          resp
        end 
        alias_method_chain :request, :bugflow 
      end
    end

    def call(env)
      @request_monitor = BugFlow::Request.new
      @request_monitor.env = env
      begin
        out = @app.call(env)
        out
      rescue Exception => e
        @request_monitor.exception = e
        raise e
      end
    end
  end
end