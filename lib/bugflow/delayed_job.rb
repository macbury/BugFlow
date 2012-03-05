if defined?(Delayed)
  Delayed::Worker.class_eval do
    def handle_failed_job_with_bugflow(job, error)
      handle_failed_job_without_bugflow(job, error)

      begin
        env = {
          "job.name" => job.name,
          "job.attempts" => job.attempts,
          "job.priority" => job.priority
          "job.priority" => job.run_at,
          "job.queue" => job.queue,
          "job.failed_at" => job.failed_at,
          "job.locked_at" => job.locked_at,
          "job.locked_by" => job.locked_by,
          "job.id" => job.id
        }
        BugFlow.notify("DelayedJob", error, env)
      rescue Exception => e
        puts "BugFlow failed: #{e.class.name}: #{e.message}"
        e.backtrace.each do |f|
          puts "  #{f}"
        end
      end
    end 
    alias_method_chain :handle_failed_job, :bugflow 
    alias_method_chain :initialize, :bugflow 
  end
end