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
      log "Started!"
      EventMachine::add_periodic_timer( 5 ) { BugFlow.sync! }
    end
  end

  def self.sync!
    return if BugFlow.list.empty?
    crashes = BugFlow.list[0..100]
    url = BugFlow.config.url
    log "Sending #{crashes.size} crashes to #{url}"
    @list = []
    request_crashes = crashes.map { |crash| crash.payload.to_hash }
    http = EventMachine::HttpRequest.new(url).post(
      :body => { :crashes => request_crashes.to_yaml, :api_key => BugFlow.config.api_key },
      :connect_timeout => 3,
      :inactivity_timeout => 5,
      :redirects => 3
    )
    http.callback do
      if http.response_header.status == 200
        log "Pushed #{crashes.size} crashes to #{url} with status #{http.response_header.status}"
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
end
