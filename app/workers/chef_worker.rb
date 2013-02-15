class ChefWorker < BaseWorker
  @queue = :low

  class << self
    def perform
    end
  end
end