require 'multi_json'
require 'yaml'

module BugFlow

  class Crash
    include BugFlow::Serializer
    
    attr_reader :exception
    attr_reader :environment


    def initialize(exception)
      @exception = {
        :class_name => exception.class.to_s,
        :message    => exception.message,
        :backtrace  => exception.backtrace,
      }
    end
    
    def to_hash
      {
        :exception   => @exception,
        :environment => @environment
      }
    end
  end
end
