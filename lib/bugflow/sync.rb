require "eventmachine"
require 'em-http'
module BugFlow
  def self.list
    @list ||= []
  end

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
      log "Started loop, sync every: #{BugFlow.config.sync_time} seconds!"
      EventMachine::add_periodic_timer( BugFlow.config.sync_time ) do
        begin
          BugFlow.sync!
        rescue Exception => e
          log_error e.to_s
          log_error e.backtrace.join("\n")
        end
      end
    end
  end

  def self.sync!
    debug "Pipline: #{BugFlow.list.size}"
    return if BugFlow.list.empty?
    log "Sending #{BugFlow.list.size} requests"
    data = BugFlow.list.map(&:to_hash).to_yaml
    @list = []
    log "Streaming requests..."
    http = EventMachine::HttpRequest.new(BugFlow.config.url).post(
      :body => { :data => data, :api_key => BugFlow.config.api_key },
      :connect_timeout => 3,
      :inactivity_timeout => 5,
      :redirects => 3
    )
    debug "Streaming method end awating callback"
    http.callback do
      if http.response_header.status == 200
        log "Pushed #{crashes.size} crashes to #{BugFlow.config.url} with status #{http.response_header.status}"
      else
        log_error("BugFlow internal server error!")
        BugFlow.list << crashes
        BugFlow.list.flatten!
      end
    end
    http.errback do 
      log_error(http.error) 
      @list << crashes
      @list.flatten!
    end
  end


  def self.push(request)
    log "Adding request on pipline"
    self.list << request
  end

  def self.die_gracefully_on_signal
    log "Binding signal traps"
    Signal.trap("INT")  { EM.stop }
    Signal.trap("TERM") { EM.stop }
  end

  def self.log_error(ex)
    @config = BugFlow.config
    return if @config.logger.nil?
    if @config.logger.respond_to?(:error)
      @config.logger.error("BugFlow Error: #{ex.inspect}")
    elsif @config.logger.kind_of?(IO)
      @config.logger.puts("BugFlow Error: #{ex.inspect}")
    end
    @config.logger.flush if @config.logger.respond_to?(:flush)
  end

  def self.log(ex)
    @config = BugFlow.config
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
      @config.logger.debug("BugFlow Debug: #{ex.inspect}")
    elsif @config.logger.kind_of?(IO)
      @config.logger.puts("BugFlow Debug: #{ex.inspect}")
    end
    @config.logger.flush if @config.logger.respond_to?(:flush)
  end
end
