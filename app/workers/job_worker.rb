class JobWorker
  extend Resque::Plugins::Logger
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
  end
end