class JobWorker
  extend Resque::Plugins::Logger
  @queue = :default

  class << self
    def perform(options={ })
      id = options["id"]
      job = Job.find(id)
      logger.info "JobWorker:perform #{job.class} #{id}"

      begin
        job.status = :working
        job.save!

        job.work
        job.status = :complete
        job.save!

        job.accept
      rescue => e
        logger.error "error running job, attempting to save"
        logger.error "  #{e.message} at #{e.backtrace.first}"
        job.status = :error
        job.message = e.message
        job.trace = e.backtrace
        job.save!
      end
    rescue => e
      logger.error e.message
      logger.error e
    end
  end
end