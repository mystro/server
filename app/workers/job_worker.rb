class JobWorker
  @queue = :default

  class << self
    def perform(options={ })
      id = options["id"]
      job = Job.find(id)
      logger.info "JobWorker:perform #{job.class} #{id}"
      job.run
    rescue => e
      logger.error e.message
      logger.error e
    end

    def logger
      Resque.logger
    end
  end
end