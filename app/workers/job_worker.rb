class JobWorker
  extend Resque::Plugins::Logger
  @queue = :default

  class << self
    def perform(options={ })
      id = options["id"]
      logger.info "JobWorker:perform #{id}"
      job = Job.find(id)

      begin
        job.status = :working
        job.save!

        job.work
        job.status = :complete
        job.save!

        job.accept
      rescue => e
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