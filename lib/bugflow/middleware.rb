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
      ActiveSupport::Notifications.subscribe "process_action.action_controller" do
        @request_monitor.finish!
      end
    end

    def call(env)
      @request_monitor = BugFlow::Request.new
      @request_monitor.env = env
      begin
        out = @app.call(env)
        cpu_after = `ps -o %cpu #{$$}`.strip.gsub(/[^0-9\.]+/,"").to_f
        mem_after = `ps -o rss= -p #{$$}`.to_i
        BugFlow.debug "AFTER(CPU/MEM): #{cpu_after}% #{mem_after} MB"
        out
      rescue Exception => e
        @request_monitor.exception = e
        raise e
      end
    end
  end
end