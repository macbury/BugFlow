module BugFlow
  class View
    attr_accessor :start_time, :render_time, :template, :is_partial
    def initialize(start_time, end_time, payload)
      self.start_time = start_time
      self.render_time = end_time - start_time
      self.template = payload[:virtual_path]
      self.is_partial = !self.template.split("/").last.match(/\A_/i).nil?
    end

    def to_hash
      {
        :start_time => self.start_time,
        :render_time => self.render_time,
        :template => self.template,
        :is_partial => self.is_partial
      }
    end
  end
end