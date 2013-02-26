class MystroWorker
  extend Resque::Plugins::Logger
  @queue = :default

  class << self
    def perform(options={ })
      job = Jobs::Cloud::Update.create!
      job.enqueue
    rescue => e
      logger.error e.message
      logger.error e
    end
  end
end