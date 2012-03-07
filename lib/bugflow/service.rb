module BugFlow

  class Service
    attr_accessor :start_time, :duration, :host
    def initialize(start_time, end_time, payload)
      self.start_time = start_time
      self.duration = end_time - start_time
      self.host = payload[:host]
    end

    def to_hash
      {
        :start_time => self.start_time,
        :duration => self.duration,
        :sql => self.sql,
        :name => self.name
      }
    end
  end

end