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
        cpu = `ps -o %cpu #{$$}`.strip.gsub(/[^0-9\.]+/,"").to_f
        mem = `ps -o rss= -p #{$$}`.to_i
        Rails.logger.info "BEFORE(CPU/MEM): #{cpu}% #{mem} MB"
        @app.call(env)
        cpu = `ps -o %cpu #{$$}`.strip.gsub(/[^0-9\.]+/,"").to_f
        mem = `ps -o rss= -p #{$$}`.to_i
        Rails.logger.info "AFTER(CPU/MEM): #{cpu}% #{mem} MB"
      rescue Exception => e
        @request_monitor.exception = e
        raise
      end
    end
  end
end