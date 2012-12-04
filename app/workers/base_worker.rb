class BaseWorker
  extend Resque::Plugins::Logger
  @queue = :default

  class << self
    def perform(action, options={ })
      mopt = Hashie::Mash.new(options)

      id      = mopt.id.to_s
      user    = mopt.user
      object  = model.unscoped.find(id)
      account = object.account ? Mystro::Account.list[object.account.name] : nil

      raise "must specify model id" unless id
      raise "could not find model object" unless object
      raise "must specify mystro account #{object.inspect}" unless account
      raise "unknown action #{action} for worker #{self.name}" unless respond_to?("perform_#{action.to_s}")

      logger.info "sending #{self.name}#perform_#{action.to_s}(#{object}, #{account}, user: #{user})"
      send("perform_#{action.to_s}", object, account) #TODO: add user, so that it can be associated with model
    rescue => e
      logger.error "perform error: #{e.message} at #{e.backtrace.first}"
      logger.debug e
    end

    def model
      name.gsub("Worker", "").constantize
    end

    def wait_for(list=nil)
      return unless list && list.count
      #logger.info "#{self.name} waiting"
      #while list.map {|e| e.reload}.select {|e| e.synced_at.nil?}.count > 0 do
      #  sleep 3
      #end
      classes = list.map { |e| e.class }.uniq
      logger.info "#{self.name} waiting for list of #{classes.join(",")}"
      wait do
        list.each { |e| e.reload }
        unsynced = list.select { |e| e.synced_at.nil? }
        unsynced.count > 0
      end
    end

    # wait while return value from block is true
    def wait(options = { }, &block)
      return unless block_given?
      o = {
          :interval => 3
      }.merge(options)
      while yield do
        sleep o[:interval]
      end
    end
  end
end