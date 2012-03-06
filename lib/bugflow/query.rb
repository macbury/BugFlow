module BugFlow

  class Query
    attr_accessor :start_time, :query_time, :sql, :name
    def initialize(start_time, end_time, payload)
      self.start_time = start_time
      self.query_time = end_time - start_time
      self.sql = payload[:sql]
      self.name = payload[:name]
    end

    def to_hash
      {
        :start_time => self.start_time,
        :render_time => self.render_time,
        :sql => self.sql,
        :name => self.name
      }
    end
  end

end