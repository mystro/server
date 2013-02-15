class MystroWorker < BaseWorker
  @queue = :low

  class << self
    def perform
    rescue => e
      puts "fail: #{e.message} at #{e.backtrace.first}"
      puts "#{e.backtrace.join("\n")}"
      false
    end
  end
end