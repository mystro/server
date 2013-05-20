class ChefWorker
  @queue = :default

  class << self
    def perform(options={ })
      job = Jobs::Chef::Roles.create!
      job.enqueue
    rescue => e
      logger.error e.message
      logger.error e
    end
  end
end