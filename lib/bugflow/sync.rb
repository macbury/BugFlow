require "eventmachine"
require 'em-http'
module BugFlow

  def self.start!
    @config = BugFlow.config
    log "Starting sync service.."
    if defined?(PhusionPassenger)
      log "Detected PhusionPassenger"
      PhusionPassenger.on_event(:starting_worker_process) do |forked|
        if forked && EM.reactor_running?
          EM.stop
        end
        Thread.new { EM.run }
      end
    elsif defined?(Thin)
      log "Running in thin"
    else
      log "Running normal"
      Thread.new { EM.run }
    end
    die_gracefully_on_signal
    loop_sync
  end


  def self.loop_sync
    log "Starting sync"
    EM.next_tick do
      log "Started loop"
      EventMachine::add_periodic_timer( BugFlow.config.sync_time ) { BugFlow.sync! }
    end
  end

  def self.sync!
    return if BugFlow.list.empty?
    sync_list = BugFlow.list[0..100]
    log "Sending #{sync_list.size} requests"
    @list = []
    request_sync_list = sync_list.map(&:to_hash)
    log "Compressing requests"
    data = Zlib::Deflate.deflate(sync_list.to_yaml,Zlib::BEST_SPEED)
    log "Streaming requests..."
    http = EventMachine::HttpRequest.new(@config.url).post(:body => {:data => data, :api_key => @config.api_key})
    http.callback do
      if http.response_header.status == 200
        log "Pushed #{crashes.size} crashes to #{@config.url} with status #{http.response_header.status}"
      else
        log_error("BugFlow server error!")
        @list << crashes
        @list.flatten!
      end
    end
    http.errback do 
      log_error(http.error) 
      @list << crashes
      @list.flatten!
    end
  end

  def self.list
    @list ||= []
  end

  def self.push(crash)
    self.list << crash
  end

  def self.die_gracefully_on_signal
    log "Binding signal traps"
    Signal.trap("INT")  { EM.stop }
    Signal.trap("TERM") { EM.stop }
  end

  def self.log_error(ex)
    return if @config.logger.nil?
    if @config.logger.respond_to?(:error)
      @config.logger.error("BugFlow Error: #{ex.inspect}")
    elsif @config.logger.kind_of?(IO)
      @config.logger.puts("BugFlow Error: #{ex.inspect}")
    end
    @config.logger.flush if @config.logger.respond_to?(:flush)
  end

  def self.log(ex)
    return if @config.logger.nil?
    if @config.logger.respond_to?(:info)
      @config.logger.info("BugFlow: #{ex.inspect}")
    elsif @config.logger.kind_of?(IO)
      @config.logger.puts("BugFlow: #{ex.inspect}")
    end
    @config.logger.flush if @config.logger.respond_to?(:flush)
  end

  def self.debug(ex)
    return if @config.logger.nil?
    if @config.logger.respond_to?(:info)
      @config.logger.debug("BugFlow: #{ex.inspect}")
    elsif @config.logger.kind_of?(IO)
      @config.logger.puts("BugFlow: #{ex.inspect}")
    end
    @config.logger.flush if @config.logger.respond_to?(:flush)
  end
end
