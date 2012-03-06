module BugFlow
  class Request
    include BugFlow::Serializer
    attr_accessor :crash, :env, :start_time, :end_time, :action, :controller, :params, :format, :method, :path, :views, :queries

    def self.current_request
      @current_request
    end

    def self.start!(env)
      @current_request = new BugFlow::Request.new(env)
    end

    def self.finish!(exception=nil)
      @current_request.exception = exception
      @current_request.finish!
      @current_request = nil
    end

    def initialize(env)
      self.env = clean_non_serializable_data(env)
      self.start_time = Time.zone.new
      self.views = []
      self.queries = []
    end

    def exception=(new_exception)
      return if new_exception.nil?
      self.crash = BugFlow::Crash.new(self.location, self.env, new_exception)
    end

    def self.location
      [self.controller, self.action].join('#')
    end

    def edit(&block)
      yield self
    end

    def parse_payload(payload={})
      self.controller ||= payload[:controller]
      self.action     ||= payload[:action]
      self.params     ||= payload[:params]
      self.format     ||= payload[:format]
      self.method     ||= payload[:method]
      self.path       ||= payload[:path]
    end

    def finish!
      self.end_time = Time.zone.now
      BugFlow.push(self)
    end

    def request_time
      self.end_time - self.start_time
    end

    def to_hash
      out = {
        :environment => self.env,
        :location    => self.location,
        :controller  => self.controller,
        :action      => self.action,
        :params      => self.params,
        :format      => self.format,
        :method      => self.method,
        :path        => self.path,
        :request_time => self.request_time,
        :start_time  => self.start_time,
        :views       => self.views.map(&:to_hash),
        :queries     => self.queries.map(&:to_hash),
      }

      out[:crash] = self.crash.to_hash if self.crash
      out
    end
  end
end
