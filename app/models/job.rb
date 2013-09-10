class Job
  include Qujo::Database::Mongoid

  include Qujo::Queue::Resque

  include Qujo::Concerns::Common
  include Qujo::Concerns::Logging
  include Qujo::Concerns::Status

  def mystro
    @mystro ||= begin
      if model && model.organization
        a = model.organization
        Mystro::Organization.get(a.name)
      end
    rescue => e
      pushlog(:error, "problem getting mystro organization")
    end
  end

  # wait for objects be synced (set synced_at value)
  def wait_for(list=nil)
    return unless list && list.count
    classes = list.map { |e| e.class }.uniq
    logger.info "#{self.class.name}##{self.id} waiting for list of #{classes.join(",")}"
    wait do
      list.each { |e| e.reload }
      unsynced = list.select { |e| e.synced_at.nil? }
      unsynced.count > 0
    end
  end

end
