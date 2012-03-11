require "eventmachine"
require 'em-http'
require "zlib"
require "base64"
require "amqp"
module BugFlow
  def self.list
    @list ||= []
  end

  def self.gather_performance_data
    cpu = `ps -o %cpu #{$$}`.strip.gsub(/[^0-9\.]+/,"").to_f
    ram = `ps -o rss= -p #{$$}`.to_i
    BugFlow.debug "AFTER(CPU/MEM): #{cpu}% #{ram} MB"
    [cpu, ram]
  end

  def self.start!
    @config = BugFlow.config
    log "Starting sync service under #{$$} pid"
    if defined?(PhusionPassenger)
      log "Detected PhusionPassenger"
      PhusionPassenger.on_event(:starting_worker_process) do |forked|
        log "Process forked: #{$$}"
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
    sleep 0.5
    die_gracefully_on_signal
    
    begin
      loop_sync
    rescue Exception => e
      log_error e.to_s
      log_error e.backtrace.join("\n")
    end
  end

  def self.connect!
    log "Connecting to ampq server..."
    @connection = AMQP.connect :user => "bugflow", :pass => "test", :vhost => "/requests"
    log "Binding channel"
    @channel = AMQP::Channel.new(@connection, :auto_recovery => true)
  end

  def self.loop_sync
    log "Starting sync"
    EM.next_tick do
      connect!
      log "Started loop, sync every: #{BugFlow.config.sync_time} seconds!"
    end
  end

  def self.sync!
    debug "Pipline: #{BugFlow.list.size}"
    
    return if BugFlow.list.empty?
    log "Sending #{BugFlow.list.size} requests"
    debug BugFlow.list.map(&:to_hash).inspect
    data = BugFlow.list.map(&:to_hash).to_yaml
    compressed_data = Base64.strict_encode64(Zlib::Deflate.deflate(data, Zlib::BEST_COMPRESSION))

    @list = []
    log "Streaming requests..."
    url = File.join(BugFlow.config.url, BugFlow::API_VERSION, "sync")
    http = EventMachine::HttpRequest.new(url).post(
      :body => { :data => compressed_data, :api_key => BugFlow.config.api_key, :app_time => Time.new },
      :connect_timeout => 3,
      :inactivity_timeout => 5,
      :redirects => 3
    )
    debug "Streaming method end awating callback"
    http.callback do
      debug "Recived response: #{http.response_header.status}"
      if http.response_header.status.to_i == 200
        log "Pushed to #{url} with status #{http.response_header.status}"
      else
        log_error("BugFlow internal server error!")
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
    #self.list << request
    @channel.default_exchange.publish(request.to_hash.to_yaml, :routing_key => "requests.ruby")
  end

  def self.die_gracefully_on_signal
    log "Binding signal traps"
    Signal.trap("INT")  { 
      log "Recived INT signal for #{$$}"
      EM.stop 
    }
    Signal.trap("TERM") { 
      log "Recived TERM signal for #{$$}"
      EM.stop 
    }
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
